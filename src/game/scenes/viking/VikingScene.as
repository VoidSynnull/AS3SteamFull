package game.scenes.viking
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.managers.SoundManager;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.entity.character.part.SkinPart;
	import game.components.timeline.Timeline;
	import game.creators.animation.FSMStateCreator;
	import game.creators.entity.AnimationSlotCreator;
	import game.data.animation.entity.character.Overhead;
	import game.data.animation.entity.character.PlacePitcher;
	import game.data.animation.entity.character.PointPistol;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.AudioGroup;
	import game.scene.template.PlatformerGameScene;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.entity.character.states.touch.JumpState;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.GeomUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class VikingScene extends PlatformerGameScene
	{
		protected var _audioGroup:AudioGroup;
		protected var _events:VikingEvents;
		protected var _currentUnderling:Entity;
		protected var _finalCup:Boolean;
		
		protected const WALK_SPEED:Number 		= 	300;
		protected const NORMAL_SPEED:Number 	= 	800;
		protected const CHALICE:String			= 	"viking_chalice";
		protected const GOBLET:String			=	"viking_goblet";
		protected const GIANT:String			= 	"giant";
		protected const THORLAK:String			=	"thorlak";
		protected const UNDERLING:String		=	"underling_";
		protected var _givingDrink:Boolean = false;
		
		
		override public function destroy():void
		{
			shellApi.eventTriggered.remove(eventTriggered);
			super.destroy();
		}
		
		override public function loaded():void
		{
			_events = shellApi.islandEvents as VikingEvents;
			if( !_audioGroup )
			{
				_audioGroup = getGroupById(AudioGroup.GROUP_ID) as AudioGroup;
			}
			
			if( SkinUtils.hasSkinValue( player, SkinUtils.ITEM, "viking_goblet" ))
			{
				SkinUtils.emptySkinPart( player, SkinUtils.ITEM );
			}
			
			shellApi.eventTriggered.add( eventTriggered );
			
			if(( shellApi.sceneName == "ThroneRoom" || shellApi.sceneName == "DiningHall" ) &&  shellApi.checkEvent( _events.HOLDING_TRAY ))
			{
				if( shellApi.checkEvent( _events.HAS_DRINK + "1" ) || shellApi.checkEvent( _events.HAS_DRINK + "2" ) 
				  || shellApi.checkEvent( _events.HAS_DRINK + "3" ) || shellApi.checkEvent( _events.GOBLET_PLACED ))
				{
					equipTray();
				}
				else
				{
					shellApi.removeEvent( _events.HOLDING_TRAY );
				}
			}
			super.loaded();
			
		}
		
		protected function eventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
		}
		
		// COMMON TRAY LOGIC WHEN ENTERING SCENE	
		protected function equipTray():void
		{
			SkinUtils.setSkinPart( player, SkinUtils.ITEM2, "viking_tray", false, adjustTraySize );
			Timeline( player.get( Timeline )).handleLabel( "step", playDrinkStepSound, false );
		}
		
		public function playDrinkStepSound():void
		{
			var number:int = GeomUtils.randomInRange( 1, 4 );
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "metal_rattle_0" + number + ".mp3" );	
		}
		
		protected function adjustTraySize( itemPart:SkinPart ):void
		{
			var tray:Entity = SkinUtils.getSkinPartEntity( player, SkinUtils.ITEM2 );
			
			var fsmControl:FSMControl = player.get( FSMControl );
			fsmControl.removeState( CharacterState.JUMP );
			
			var rigAnim:RigAnimation = CharUtils.getRigAnim( player, 1 );
			if( rigAnim == null )
			{
				var animationSlot:Entity = AnimationSlotCreator.create( player );
				rigAnim = animationSlot.get( RigAnimation ) as RigAnimation;
			}
			
			rigAnim.next = Overhead;
			rigAnim.addParts( CharUtils.HAND_FRONT, CharUtils.HAND_BACK );
			
			var motionControl:CharacterMotionControl = player.get( CharacterMotionControl );
			motionControl.maxVelocityX = WALK_SPEED;
			
			var display:Display = tray.get( Display );
			
			// REMOVE GIVEN CUPS
			for( var number:int = 1; number < 4; number ++ )
			{
				if( !shellApi.checkEvent( _events.HAS_DRINK + number ))
				{
					display.displayObject[ "cup" + number ].visible = false;
				}
			}
			
			// REMOVE GOBLET
			if( !shellApi.checkEvent( _events.GOBLET_PLACED ))
			{
				display.displayObject[ "goblet" ].visible = false;
			}
			_finalCup = false;
		}
		
		protected function placeGobletOnTray( ):void
		{
			shellApi.completeEvent( _events.GOBLET_PLACED );
			
			var tray:Entity = SkinUtils.getSkinPartEntity( player, SkinUtils.ITEM2 );		
			var display:Display = tray.get( Display );
			var goblet:MovieClip = display.displayObject.getChildByName( "goblet" );
			goblet.visible = true;
		}
		
		// GIVING OUT DRINK LOGIC
		protected function approachViking( player:Entity, viking:Entity ):void
		{
			SceneUtil.lockInput( this, true );
		}
		
		protected function giveDrink( player:Entity, underling:Entity ):Boolean
		{
			var gotDialog:Boolean = false;
			var dialog:Dialog;
			var itemPart:SkinPart = SkinUtils.getSkinPartEntity( underling, SkinUtils.ITEM ).get( SkinPart );
			var underlingId:String = underling.get( Id ).id;
			var item:String	= CHALICE;
			
			if( !_currentUnderling )
			{
				if( itemPart.value != CHALICE )
				{
					_currentUnderling = underling;
					
					var tray:Entity = SkinUtils.getSkinPartEntity( player, SkinUtils.ITEM2 );
					var display:Display = tray.get( Display );
					var cupDisplay:DisplayObject;
					
					for( var number:int = 1; number < 4; number ++ )
					{
						if( !cupDisplay && shellApi.checkEvent( _events.HAS_DRINK + number ))
						{
							cupDisplay = display.displayObject.getChildByName( "cup" + number );
							shellApi.removeEvent( _events.HAS_DRINK + number );
							if( number == 3 && !shellApi.checkEvent( _events.GOBLET_PLACED ))
							{
								shellApi.removeEvent( _events.HOLDING_TRAY );
								_finalCup = true;
							}
						}
					}
					
					// if only goblet left
					if( !cupDisplay && shellApi.checkEvent( _events.GOBLET_PLACED ))
					{
						if( underlingId == "thorlak" )
						{
							cupDisplay = display.displayObject.getChildByName( "goblet" );
							shellApi.removeEvent( _events.GOBLET_PLACED );
							
							item = GOBLET;
							_finalCup = true;
						}
						else
						{
							dialog = underling.get( Dialog );
							dialog.sayById( "not_that_one" );
							dialog.complete.addOnce( notThatOne );
						
							shellApi.removeEvent( _events.HOLDING_TRAY );
							shellApi.removeEvent( _events.GOBLET_PLACED );
							gotDialog = true;
						}
					}
					
					if( cupDisplay )
					{
						display.displayObject.removeChild( cupDisplay );
						SkinUtils.setSkinPart( player, SkinUtils.ITEM, item, false, handGlass );
					}
				}
				else
				{
					dialog = underling.get( Dialog );
					dialog.sayById( "thanks" );
			//		dialog.complete.addOnce( unlock );
					
					gotDialog = true;
				}
			}
			return gotDialog;
		}
		
//		private function unlock( dialogData:DialogData ):void
//		{
//			SceneUtil.lockInput( this, false );
//		}
		
		private function notThatOne( dialogData:DialogData ):void
		{
			if( shellApi.sceneName != "ThroneRoom" )
			{
				SceneUtil.lockInput( this, false );
			}
			hideGobletTray();
		}
		
		protected function hideGobletTray( didNotHandDrink:Boolean = true ):void
		{			
			var rigAnim:RigAnimation = CharUtils.getRigAnim( player, 1 );
			rigAnim.manualEnd = true;
			
			if( didNotHandDrink )
			{
				rigAnim = CharUtils.getRigAnim( player, 2 );
				if( !rigAnim )
				{
					rigAnim = CharUtils.getRigAnim( player, 1 );
				}
				rigAnim.manualEnd = true;
			}
			
			var motionControl:CharacterMotionControl = player.get( CharacterMotionControl );
			motionControl.maxVelocityX = NORMAL_SPEED;
			
			var fsmCreator:FSMStateCreator = new FSMStateCreator();
			fsmCreator.createCharacterState( JumpState, player, CharacterState.JUMP );
			
			SkinUtils.emptySkinPart( player, SkinUtils.ITEM2 );
			Timeline( player.get( Timeline )).removeLabelHandler( playDrinkStepSound );
		}
		
		private function handGlass( itemPart:SkinPart ):void
		{
			var slot:Number = 2;
			
			if( _finalCup )
			{
				slot = 1;
				SkinUtils.emptySkinPart( player, SkinUtils.ITEM2 );
				
				var motionControl:CharacterMotionControl = player.get( CharacterMotionControl );
				motionControl.maxVelocityX = NORMAL_SPEED;
				
				var fsmCreator:FSMStateCreator = new FSMStateCreator();
				fsmCreator.createCharacterState( JumpState, player, CharacterState.JUMP );
				
				Timeline( player.get( Timeline )).removeLabelHandler( playDrinkStepSound );
			}
			
			var rigAnim:RigAnimation = CharUtils.getRigAnim( player, slot );
			if( rigAnim == null )
			{
				var animationSlot:Entity = AnimationSlotCreator.create( player );
				rigAnim = animationSlot.get( RigAnimation ) as RigAnimation;
			}
			
			rigAnim.next = PlacePitcher;
			rigAnim.addParts( CharUtils.HAND_FRONT );
			
			var timeline:Timeline = CharUtils.getTimeline( player, slot );
			timeline.handleLabel( "trigger", drinkHandler );
		}
		
		private function drinkHandler():void
		{
			var slot:Number = 2;
			if( _finalCup )
			{
				slot = 1;
			}
			var timeline:Timeline = CharUtils.getTimeline( player, slot );
			timeline.stop();
			_givingDrink = true;
			
			var id:Id = _currentUnderling.get( Id );
			underlingReachesForDrink();
		}
		
		// VIKING TAKES THE GLASS
		protected function underlingReachesForDrink():void
		{
			var id:Id = _currentUnderling.get( Id );
			var slot:Number = 1;
			
			var rigAnim:RigAnimation = CharUtils.getRigAnim( _currentUnderling, slot );
			if( rigAnim == null )
			{
				var animationSlot:Entity = AnimationSlotCreator.create( _currentUnderling );
				rigAnim = animationSlot.get( RigAnimation ) as RigAnimation;
			}
			
			rigAnim.next = PointPistol;
			rigAnim.addParts( CharUtils.HAND_FRONT );
			
			var timeline:Timeline = CharUtils.getTimeline( _currentUnderling, slot );
			timeline.handleLabel( "trigger", grabDrink );
		}
		
		private function grabDrink():void
		{
			var slot:Number = 2;
			if( _finalCup )
			{
				slot = 1;
			}
			var timeline:Timeline = CharUtils.getTimeline( player, slot );
			timeline.play();
						
			// SET THE RIGHT CUP ASSET ( GOBLET / CHALICE )
			var id:Id = _currentUnderling.get( Id );
			var item:String	=	CHALICE;
			if( id.id == "thorlak" )
			{
				item = GOBLET;
			}
			SkinUtils.setSkinPart( _currentUnderling, SkinUtils.ITEM, item, true, underlingHasDrink );
			SkinUtils.emptySkinPart( player, SkinUtils.ITEM );
		}
		
		// KEEP CHALICE SIZE CONSTANT WHEN PASSED BETWEEN ENTITIES
		protected function underlingHasDrink( itemPart:SkinPart ):Entity
		{
			var id:Id = _currentUnderling.get( Id );
			var chalice:Entity = CharUtils.getPart( _currentUnderling, SkinUtils.ITEM );
						
			var underling:Entity = _currentUnderling;
			_currentUnderling = null;
						
			return underling;
		}
	}
}