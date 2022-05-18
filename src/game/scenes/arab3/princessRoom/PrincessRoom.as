package game.scenes.arab3.princessRoom
{
	import com.greensock.easing.Back;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.motion.Destination;
	import game.components.motion.MotionThreshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Cry;
	import game.data.animation.entity.character.ExtendGlass;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Parachuting;
	import game.data.animation.entity.character.Place;
	import game.data.animation.entity.character.PointItem;
	import game.data.animation.entity.character.StandNinja;
	import game.data.scene.characterDialog.DialogData;
	import game.data.specialAbility.SpecialAbilityData;
	import game.data.specialAbility.islands.arab.MagicCarpet;
	import game.scene.template.CharacterGroup;
	import game.scenes.arab1.shared.groups.SmokeBombGroup;
	import game.scenes.arab3.Arab3Scene;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.MotionThresholdSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class PrincessRoom extends Arab3Scene
	{
		private var _thief:Entity;
		private var _smokeBombGroup:SmokeBombGroup;
		private const TRIGGER:String 							=	"trigger";
		
		public function PrincessRoom()
		{
			super();
		}
		
		override protected function addBaseSystems():void
		{
			super.addBaseSystems();
			addSystem( new MotionThresholdSystem());	
		}
			
		override public function init( container:DisplayObjectContainer=null ):void
		{
			super.groupPrefix = "scenes/arab3/princessRoom/";
			super.init( container );
			
			_numSpellTargets 									= 	0;
			_numThiefSpellTargets 								=	0;
		}
		
		override public function smokeReady():void
		{
			super.smokeReady();
			_smokeBombGroup = this.addChildGroup(new SmokeBombGroup(this, this._hitContainer)) as SmokeBombGroup;
			_thief = getEntityById( "thief" );
			
			Sleep( _thief.get( Sleep )).ignoreOffscreenSleep 	= 	true;
			Sleep( _thief.get( Sleep )).sleeping 				= 	false;
			
			CharacterGroup( getGroupById( CharacterGroup.GROUP_ID )).addFSM( _thief );
			
			setupDiary();
			
			var clip:MovieClip 									= 	_hitContainer[ "drawing" ];
			
			if( !shellApi.checkItemEvent( _events.DRAWING ))
			{
				var drawing:Entity = EntityUtils.createSpatialEntity( this, clip );
				drawing.add( new Id( clip.name ));
				
				Display( drawing.get( Display )).alpha			= 	0;
				SceneUtil.lockInput( this );
				
				// pan to the princess, hold for a few beats
				SceneUtil.setCameraTarget( this, _thief, false, .02 );
				SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, thiefThinks ));
			}
			else
			{
				_hitContainer.removeChild( clip );
				removeEntity( _thief );
			}
		}
		
		// DIARY LOGIC 
		private function setupDiary():void
		{
			var clip:MovieClip 									=	_hitContainer[ "diary" ];
			if( !PlatformUtils.isDesktop )
			{
				BitmapUtils.convertContainer( clip );
			}
			var entity:Entity 									= 	EntityUtils.createSpatialEntity( this, clip );
			entity.add( new Id( clip.name )).add( new AudioRange( 500 ));
			_audioGroup.addAudioToEntity( entity );
			
			InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
			ToolTipCreator.addToEntity( entity );
			
			var sceneInteraction:SceneInteraction 				= 	new SceneInteraction();
			sceneInteraction.reached.add( approachDiary );
			entity.add( sceneInteraction );
		}
		
		override protected function eventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if( event == _events.USE_SKELETON_KEY )
			{
				if( CharUtils.hasSpecialAbility( player, MagicCarpet))
				{
					CharUtils.removeSpecialAbilityByClass( player, MagicCarpet, true );
					
					var motionThreshold:MotionThreshold 		= 	new MotionThreshold( "velocity", "==" );
					motionThreshold.axisValue 					= 	"y";
					motionThreshold.threshold 					= 	0;
					motionThreshold.entered.addOnce( moveToDiaryPosition );
					
					player.add( motionThreshold );
				}
				else
				{
					moveToDiaryPosition();
				}
			}
			else
			{
				super.eventTriggered( event, makeCurrent, init, removeEvent );
			}
		}
		
		private function moveToDiaryPosition():void
		{
			var diary:Entity 									= 	getEntityById( "diary" );
			var spatial:Spatial 								= 	diary.get( Spatial );
			
			var destination:Destination 						= 	CharUtils.moveToTarget( player, 1490, spatial.y, false, Command.create( approachDiary, diary, true ));
			destination.validCharStates 						= 	new Vector.<String>;
			destination.validCharStates.push( CharacterState.STAND, CharacterState.WALK );
		}
		
		// MEET THE THIEF
		private function thiefThinks():void
		{
			CharUtils.setAnim( _thief, ExtendGlass );
			var timeline:Timeline = _thief.get( Timeline );
			timeline.handleLabel( "ending", thiefSobs );
			
			var charMotionControl:CharacterMotionControl = player.get( CharacterMotionControl );
			charMotionControl.maxVelocityX = 200;
		}
		
		private function thiefSobs():void
		{	
			CharUtils.setAnim( _thief, Cry );
			var timeline:Timeline = _thief.get( Timeline );
			timeline.handleLabel( "stand", thiefBecomesAware );
		}
		
		private function thiefBecomesAware():void
		{
			var dialog:Dialog 									= 	_thief.get( Dialog );

			CharUtils.setAnim( _thief, StandNinja );
			dialog.sayById( "huh" );
			dialog.complete.addOnce( regainComposure );
		}
		
		private function regainComposure( dialogData:DialogData ):void
		{
			var spatial:Spatial 								= 	player.get( Spatial );
			spatial.x 											= 	840;
			spatial.y 											=	670;
			
			var playerSpatial:Spatial 							= 	player.get( Spatial );
			var thiefSpatial:Spatial 							= 	_thief.get( Spatial );
			
			var dialog:Dialog 									= 	_thief.get( Dialog );
			dialog.sayById( "you_there" );
			dialog.complete.addOnce( justYou );
			
			CharUtils.setAnim( player, Grief );
			SceneUtil.setCameraPoint( this, playerSpatial.x + ( .5 * ( thiefSpatial.x - playerSpatial.x )), thiefSpatial.y ); 
		}
		
		private function justYou( dialogData:DialogData ):void
		{
			var dialog:Dialog 									= 	_thief.get( Dialog );
			dialog.sayById( "out_of_my_way" );
			dialog.complete.addOnce( noticePaper );
		}
		
		private function noticePaper( dialogData:DialogData ):void
		{			
			CharUtils.setAnim( _thief, Parachuting );
			var timeline:Timeline = _thief.get( Timeline );
			timeline.handleLabel( "loop", poofOut );
		}
		
		private function poofOut():void
		{
			var drawing:Entity 									= 	getEntityById( "drawing" );
			
			var display:Display 								= 	drawing.get( Display );
			display.alpha 										= 	1;
			
			var spatial:Spatial 								= 	drawing.get( Spatial );
			spatial.y 											-= 	20;
			
			ToolTipCreator.addToEntity( drawing );
			
			var tween:Tween 									= 	new Tween();
			tween.to( drawing.get( Spatial ), 2, { x : spatial.x - 20, y : spatial.y + 20, rotation : 10, ease : Back.easeInOut, onComplete : moveToPaper });
			drawing.add( tween );
			
			_smokeBombGroup.thiefAt( _thief.get(Spatial), true, true );
			SceneUtil.setCameraTarget( this, player, false, .02 );
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "small_explosion_03.mp3" );
			display				 								= 	_thief.get( Display );
			display.visible 									= 	false;
		}
		 
		private function moveToPaper():void
		{
			SceneUtil.setCameraTarget( this, player, true, .2 );
			removeEntity( _thief );
			
			var spatial:Spatial 								= 	getEntityById( "drawing" ).get( Spatial ); 
			CharUtils.moveToTarget( player, spatial.x, spatial.y, true, pickUpPaper );
		}
		
		private function pickUpPaper( player:Entity ):void
		{
			CharUtils.setAnim( player, Place );
			
			var timeline:Timeline 								= 	player.get( Timeline );
			timeline.handleLabel( "trigger", getDrawing );
		}
		
		private function getDrawing():void
		{			
			shellApi.getItem( _events.DRAWING, null, true, regainControl );
			_hitContainer.removeChild( _hitContainer[ "drawing" ]);
		}
		
		private function regainControl():void
		{
			var charMotionControl:CharacterMotionControl 		= 	player.get( CharacterMotionControl );
			charMotionControl.maxVelocityX 						= 	800;
			
			shellApi.completeEvent( _events.GENIE_IN_BAZAAR );
			SceneUtil.lockInput( this, false );
		}
		
		// DIARY
		private function approachDiary( player:Entity, diary:Entity, usedItem:Boolean = false ):void
		{
			if( usedItem )
			{
				CharUtils.setAnim( player, PointItem );
				SkinUtils.setSkinPart( player, SkinUtils.ITEM, "an_key" );
				
				var timeline:Timeline 							= 	player.get( Timeline );
				timeline.handleLabel( "pointing", openDiary );
			}
			else
			{
				var dialog:Dialog 								= 	player.get( Dialog );
				dialog.sayById( "cant_open_diary" );
			}
		}
		
		private function openDiary():void
		{			
			var audio:Audio 									=	getEntityById( "diary" ).get( Audio );
			audio.playCurrentAction( TRIGGER );
			
			var diaryPopup:DiaryPopup 							= 	addChildGroup( new DiaryPopup( overlayContainer )) as DiaryPopup;
			diaryPopup.closeClicked.addOnce( jinnsName );
		}
		
		public function jinnsName( diaryPopup:DiaryPopup ):void
		{
			SkinUtils.emptySkinPart( player, SkinUtils.ITEM );
			
			var dialog:Dialog 									= 	player.get( Dialog );
			dialog.sayById( "jinn_name" );
			
			if( !shellApi.checkEvent( _events.LEARNED_JINNS_NAME ))
			{
				shellApi.completeEvent( _events.LEARNED_JINNS_NAME );
			}
		}
	}
}