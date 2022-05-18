package game.scenes.viking.throneRoom
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.Npc;
	import game.components.entity.character.part.SkinPart;
	import game.components.entity.character.part.eye.Eyes;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.CurrentHit;
	import game.components.motion.Edge;
	import game.components.motion.MotionThreshold;
	import game.components.motion.SceneObjectMotion;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.specialAbility.SpecialAbilityControl;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.scene.SceneItemCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Angry;
	import game.data.animation.entity.character.Focus;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Stomp;
	import game.data.animation.entity.character.Throw;
	import game.data.animation.entity.character.Tremble;
	import game.data.animation.entity.character.WalkNinja;
	import game.data.display.BitmapWrapper;
	import game.data.scene.characterDialog.DialogData;
	import game.data.specialAbility.SpecialAbilityData;
	import game.data.specialAbility.character.BobbleHead;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.ItemGroup;
	import game.scenes.viking.VikingScene;
	import game.systems.SystemPriorities;
	import game.systems.entity.EyeSystem;
	import game.systems.hit.ItemHitSystem;
	import game.systems.motion.MotionThresholdSystem;
	import game.systems.motion.SceneObjectMotionSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.specialAbility.SpecialAbilityControlSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class ThroneRoom extends VikingScene
	{
		private const ERIK:String		=	"erik";
		private const HELMET:String		= 	"helmet";
		private const LIGHT:String		=	"light";
		private const CANDLE:String		=	"candle";	
		private const FLAME:String		=	"flame";
		private const TORCH:String		=	"torch";
		private const TRIGGER:String 	= 	"trigger";
		
		private var _underlings:Vector.<Entity>;
		
		private var alreadyThrough:Boolean = false;
		
		public function ThroneRoom()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/viking/throneRoom/";
			
			super.init(container);
		}
		
		override protected function addBaseSystems():void
		{
			addSystem( new MotionThresholdSystem());
			addSystem( new SceneObjectMotionSystem());
			addSystem( new ThresholdSystem());
			addSystem( new SpecialAbilityControlSystem());
			
			super.addBaseSystems();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		
		// all assets ready
		override public function loaded():void
		{
			CharUtils.addSpecialAbility( getEntityById( ERIK ), new SpecialAbilityData( BobbleHead ), true );
			SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, addBobbleyHead ));
			
//			super.loaded();
//			_underlings = new <Entity>[ getEntityById( UNDERLING + "1" )
//									, getEntityById( UNDERLING + "2" )
//									, getEntityById( UNDERLING + "3" )
//									, getEntityById( THORLAK )];
//			setupAssets();
		}

		private function setupAssets():void
		{
			var chair:Entity;
			var clip:MovieClip;
			var entity:Entity;
			var eyes:Eyes;
			var flameSequence:BitmapSequence;
			var interaction:Interaction;
			var number:int;
			var sceneInteraction:SceneInteraction;
			var sequence:BitmapSequence;
			var spatial:Spatial;
			var timeline:Timeline;
			var underling:Entity;
			var wrapper:BitmapWrapper;
			
			clip = _hitContainer[ "throne" ];
			wrapper = DisplayUtils.convertToBitmapSprite( clip, null, PerformanceUtils.defaultBitmapQuality );
			chair = EntityUtils.createSpatialEntity( this, wrapper.sprite );
			chair.add( new Id( clip.name ));
			
			getEntityById( ERIK ).remove( Npc );
		 	DisplayUtils.moveToOverUnder( Display( getEntityById( ERIK ).get( Display )).displayObject, Display( chair.get( Display )).displayObject, false );
			
			for( number = 1; number < 3; number ++ )
			{
				// LIGHT ANIMATION
				clip = _hitContainer[ LIGHT + number ];
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( clip.name ));
				
				BitmapTimelineCreator.convertToBitmapTimeline( entity, clip, true, sequence, PerformanceUtils.defaultBitmapQuality );
				Timeline( entity.get( Timeline )).playing = true;
				
				// TORCHES
				clip = _hitContainer[ TORCH + number ];
				wrapper = DisplayUtils.convertToBitmapSprite( clip, null, PerformanceUtils.defaultBitmapQuality );
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( clip.name ));
				
				// FLAMES
				clip = _hitContainer[ FLAME + number ];
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( clip.name ));
				entity.add( new AudioRange( 400 ));
				_audioGroup.addAudioToEntity( entity );
				Audio( entity.get( Audio )).playCurrentAction( TRIGGER );
				
				BitmapTimelineCreator.convertToBitmapTimeline( entity, clip, true, sequence, PerformanceUtils.defaultBitmapQuality );
				Timeline( entity.get( Timeline )).playing = true;
			}
			
			var helmet:Entity = EntityUtils.createSpatialEntity( this, _hitContainer[ HELMET ]);
			helmet.add( new Id( HELMET ));
			
			// RUN ERIK'S TANTRUM	
			if( !shellApi.checkEvent( _events.THORLAK_FRAMED ))
			{	
				for( number = 1; number < 4; number ++ )
				{
					underling = getEntityById( UNDERLING + number );
					eyes = SkinUtils.getSkinPartEntity( underling, SkinUtils.EYES ).get( Eyes );
					eyes.pupilsFollow = false;
					
					SkinUtils.setEyeStates( underling, "", EyeSystem.FRONT, true );
					
					if( number == 1 )
					{
						stripUnderling( underling );
						sceneInteraction = underling.get( SceneInteraction );
						
						sceneInteraction.minTargetDelta = new Point( 100, 100 );
						sceneInteraction.reached.add( approachViking );
					}
					else
					{
						stripUnderling( underling, true );
						underling = getEntityById( UNDERLING + number );
						underling.remove( SceneInteraction );
						underling.remove( Interaction );
						ToolTipCreator.removeFromEntity( underling );
					}
				}
				
				// SETUP THORLAK
				underling = getEntityById( THORLAK );
				
				eyes = SkinUtils.getSkinPartEntity( underling, SkinUtils.EYES ).get( Eyes );
				eyes.pupilsFollow = false;
				
				stripUnderling( underling, true );
				SkinUtils.setEyeStates( underling, "", EyeSystem.FRONT, true );
				
				// REMOVE ERIK'S INTERACTIONS TOO
				underling = getEntityById( ERIK );
				stripUnderling( underling, true );
				
				timeline = underling.get( Timeline );
				if( !shellApi.checkEvent( _events.LOOKING_FOR_GOBLET ))
				{
					// SET PLAYER WALK SPEED AND SET PAN TO ERIK
					SceneUtil.lockInput( this );
					
					var motionControl:CharacterMotionControl = player.get( CharacterMotionControl );
					motionControl.maxVelocityX = WALK_SPEED;
					SceneUtil.setCameraTarget( this, underling, false, .02 );
					CharUtils.setAnim( underling, Angry );
						
					timeline.handleLabel( "ending", questionTheMen );
					CharUtils.moveToTarget( player, 900, 880, true );
				}
				else
				{
					CharUtils.setDirection( underling, false );
					CharUtils.setAnim( underling, Focus );
					SkinUtils.setEyeStates( underling, EyeSystem.CLOSED, true );
					
					timeline.handleLabel( "trigger", timeline.stop );
					returnControl( null );
				}
				
				Display( helmet.get( Display )).visible = false;
			}
			else
			{
				for each( underling in _underlings )
				{
					removeEntity( underling );
				}
				
				SkinUtils.setEyeStates( getEntityById( ERIK ), EyeSystem.OPEN, EyeSystem.FRONT, true );
				SkinUtils.setSkinPart( getEntityById( ERIK ), SkinUtils.HAIR, "comic_erik2" );
				SkinUtils.setSkinPart( getEntityById( ERIK ), SkinUtils.ITEM, "viking_goblet" );
				
				if( !shellApi.checkItemEvent( _events.HELMET ))
				{
					spatial = helmet.get( Spatial );
					spatial.x = 1203;
					spatial.y = 875;
					
					var creator:SceneItemCreator = new SceneItemCreator();
					creator.make( helmet );
				}
				else
				{
					removeEntity( helmet );
				}
			}
			
			if( !shellApi.checkItemEvent( _events.HELMET ))
			{
				if(!super.getSystem( ItemHitSystem ))	// items require ItemHitSystem, add system if not yet added
				{
					var itemHitSystem:ItemHitSystem = new ItemHitSystem();
					super.addSystem( itemHitSystem, SystemPriorities.resolveCollisions );
				}
				
				var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
				itemHitSystem.gotItem.add( itemGroup.itemHit );
			}
		}
		
		private function stripUnderling( underling:Entity, andTooltip:Boolean = false ):void
		{
			Sleep( underling.get( Sleep )).ignoreOffscreenSleep = true;
			var dialog:Dialog = underling.get( Dialog );
			dialog.faceSpeaker = false;
			
			if( andTooltip )
			{
				var clip:MovieClip = Display( underling.get( Display )).displayObject as MovieClip;
				clip.mouseChildren = false;
				clip.mouseEnabled = false;
				underling.remove( SceneInteraction );
				underling.remove( Interaction );
				ToolTipCreator.removeFromEntity( underling );
			}
		}
		
		private function addBobbleyHead(...args ):void
		{
			var hairEntity:Entity;
			var nodes:NodeList = systemManager.getNodeList( SpecialAbilityNode );
			var node:SpecialAbilityNode;
			var specialData:SpecialAbilityData;
			var spatial:Spatial;
			var timeline:Timeline;
			
			for( node = nodes.head; node; node = node.next )
			{
				if( node.entity.get( Id ).id == ERIK )
				{
					var control:SpecialAbilityControl = node.specialControl;
					timeline = node.entity.get( Timeline );
					
					if ( control != null )
					{
						specialData = control.specials[ 0 ];
						specialData.specialAbility.activate( node );
					}
					
					hairEntity = CharUtils.getPart( node.entity, CharUtils.HAIR );
					spatial = hairEntity.get(Spatial);
					spatial.scaleX = spatial.scaleY = 1.4;
				}
			}
			
			
			super.loaded();
			_underlings = new <Entity>[ getEntityById( UNDERLING + "1" )
				, getEntityById( UNDERLING + "2" )
				, getEntityById( UNDERLING + "3" )
				, getEntityById( THORLAK )];
			
			setupAssets();
		}
		
		private function removeUnderling( underling:Entity ):void
		{
			removeEntity( underling );
		}
		
		override protected function eventTriggered( event:String, makeCurrent:Boolean=true, init:Boolean=false, removeEvent:String=null ):void
		{
			var timeline:Timeline = getEntityById( ERIK ).get( Timeline );
			var erik:Entity = getEntityById( ERIK );
			
			if( event == _events.USE_GOBLET )
			{
				if( shellApi.checkEvent( _events.HOLDING_TRAY ))
				{
					placeGobletOnTray();
				}
				else
				{
					Dialog( player.get( Dialog )).sayById( "dont_get_caught" );
				}
			}
			
			// ERIK LOOKS AWAY
			if( event == _events.TURN_BLIND_EYE )
			{
				CharUtils.setDirection( erik, false );
				CharUtils.setAnim( erik, Focus );
				SkinUtils.setEyeStates(erik, EyeSystem.CLOSED, null, true );
				
				timeline.handleLabel( "trigger", turnAndCount );
			}
			
			// ERIK TURNS TO THE CROWD AND STARTLES THE MEN
			if( event == _events.ERIK_TURNS )
			{
				SceneUtil.setCameraTarget( this, erik, false, .02 );
				timeline.play();
				CharUtils.setDirection( erik, true );
				
				SkinUtils.setEyeStates( erik, EyeSystem.OPEN, EyeSystem.FRONT, true );
				
				var dialog:Dialog = erik.get( Dialog );
				dialog.sayById( "done" );
				dialog.complete.addOnce( scanMen );
				
				var underling:Entity;
				
				for each( underling in _underlings )
				{
					CharUtils.setAnim( underling, Grief );
				}
			}
			
			if( event == _events.FLIP_A_LID )
			{
				CharUtils.setAnim( erik, Throw );
				timeline.handleLabel( "trigger", erikTantrum );
			}
			
			if( event == "stagger_response" )
			{
				staggerResponse();
			}
			
			super.eventTriggered( event, makeCurrent, init, removeEvent );
		}
		
		// ERIKS LOGIC
		private function questionTheMen():void
		{
			var dialog:Dialog = getEntityById( ERIK ).get( Dialog );
			dialog.sayById( "listen" );
		}
		
		private function turnAndCount():void
		{
			var timeline:Timeline = getEntityById( ERIK ).get( Timeline );
			timeline.stop();
			SceneUtil.setCameraTarget( this, player, false, .02 );
			
			if( !shellApi.checkEvent( _events.LOOKING_FOR_GOBLET ))
			{
				shellApi.completeEvent( _events.LOOKING_FOR_GOBLET )
			}
			
			var number:int = GeomUtils.randomInRange( 1, 3 );
			var dialog:Dialog = getEntityById( UNDERLING + number ).get( Dialog );
			dialog.sayById( "grumble" );
			dialog.complete.addOnce( returnControl );
		}
		
		private function scanMen( dialogData:DialogData ):void
		{
			var thorlak:Entity = getEntityById( THORLAK );
			var itemPart:SkinPart = SkinUtils.getSkinPartEntity( thorlak, SkinUtils.ITEM ).get( SkinPart );
			var dialog:Dialog = getEntityById( ERIK ).get( Dialog );
				
			if( itemPart.value == GOBLET )
			{
				player.remove( Threshold );
				CharUtils.setAnim( getEntityById( ERIK ), Stomp );
				SkinUtils.setEyeStates( getEntityById( ERIK ), EyeSystem.ANGRY, EyeSystem.FRONT, true );
				dialog.sayById( "betrayMe" );
		//		dialog.complete.addOnce( staggerResponse );
			}
			else
			{
				dialog.sayById( "noOne" );
			}
			
			var underling:Entity;

			for each( underling in _underlings )
			{
				dialog = underling.get( Dialog );
				dialog.faceSpeaker = false;
			}
		}
		
		private function staggerResponse():void
		{
			CharUtils.setAnim( getEntityById( THORLAK ), Throw );
			var timeline:Timeline = getEntityById( THORLAK ).get( Timeline );
			timeline.handleLabel( "trigger", tossGoblet );
		}
		
		private function tossGoblet():void
		{
			SkinUtils.setSkinPart( getEntityById( THORLAK ), SkinUtils.ITEM, "empty" );
			
			var underling:Entity;
			for each( underling in _underlings )
			{
				if( underling == getEntityById( THORLAK ))
				{
					CharUtils.setAnim( underling, Tremble );
					Dialog( underling.get( Dialog )).sayById( "noJudgement" );
				}
				else
				{
					CharUtils.stateDrivenOff( underling, 0 );
					CharUtils.setAnim( underling, WalkNinja );
					
					SkinUtils.setEyeStates( underling, EyeSystem.OPEN, EyeSystem.FRONT );
					var timeline:Timeline = underling.get( Timeline );
					timeline.reverse = true;
					
					var motion:Motion = underling.get( Motion );
					if( !motion )
					{
						motion = new Motion();
						underling.add( motion );
					}
					motion.velocity.x = 50;
				}
			}
		}
		
		private function returnControl( dialogData:DialogData ):void
		{
			if( !shellApi.checkEvent( _events.HOLDING_TRAY ))
			{
				var motionControl:CharacterMotionControl = player.get( CharacterMotionControl );
				motionControl.maxVelocityX = NORMAL_SPEED;
			}
			
			SceneUtil.setCameraTarget( this, player, false, .2 );
			SceneUtil.lockInput( this, false );
			
			var item:SkinPart = SkinUtils.getSkinPart( player, SkinUtils.ITEM2 );
			var faceMe:Boolean = item.value != "viking_tray" ? false : true;
			
			if( !alreadyThrough )
			{
				var threshold:Threshold = new Threshold( "x", "<", getEntityById( UNDERLING + "1" ), 20 );
				threshold.entered.add( Command.create( approachViking, player, getEntityById( UNDERLING + "1" )));
				player.add( threshold );
				alreadyThrough = true;
			}
			
			else
			{
				faceMe = false;
			}
			
			for( var number:int = 1; number < 4; number ++ )
			{
				Dialog( getEntityById( UNDERLING + number ).get( Dialog )).faceSpeaker = faceMe;
			}
			Dialog( getEntityById( THORLAK ).get( Dialog )).faceSpeaker = faceMe;
			
		}
		
		private function erikTantrum():void
		{
			var underling:Entity;
			
			for each( underling in _underlings )
			{
				underling.remove( SceneInteraction );
				CharUtils.moveToTarget( underling, 1610, 820, true, removeUnderling );
			}
			
			SkinUtils.setSkinPart( getEntityById( ERIK ), SkinUtils.HAIR, "comic_erik2" );
			
			var hairEntity:Entity = CharUtils.getPart( getEntityById( ERIK ), CharUtils.HAIR );
			var spatial:Spatial = hairEntity.get(Spatial);
			spatial.scaleX = spatial.scaleY = 1.4;
			
			// THROW THE HELMET
			var helmet:Entity = getEntityById( HELMET );
			Display( helmet.get( Display )).visible = true;
			
			var motion:Motion	= new Motion();
			motion.friction 	= new Point( 0, 0 );
			motion.maxVelocity 	= new Point( 1000, 1000 );
			motion.minVelocity 	= new Point( 0, 0 );
			motion.acceleration = new Point( 0, MotionUtils.GRAVITY );
			motion.velocity.x 	= 500;
			motion.velocity.y 	= -900;
			
			var sceneObjectMotion:SceneObjectMotion = new SceneObjectMotion();
			sceneObjectMotion.platformFriction = 500;
			sceneObjectMotion.rotateByVelocity = false;
			
			var motionThreshold:MotionThreshold = new MotionThreshold( "velocity" );
			motionThreshold.axisValue = "y";
			motionThreshold.operator = "<";
			motionThreshold.threshold = 0;
			motionThreshold.entered.add( helmetInMotion ); 
			
			helmet.add( new Edge( 50, 0, 50, 0 ));
			helmet.add( new BitmapCollider());
			helmet.add( new SceneCollider());
			helmet.add( new CurrentHit());
			helmet.add( new ZoneCollider());
			helmet.add( new MotionBounds( player.get( MotionBounds ).box ));
			helmet.add( new PlatformCollider());
			helmet.add( motion );
			helmet.add( motionThreshold );
			helmet.add( sceneObjectMotion );
		}
		
		private function helmetInMotion():void
		{
			var helmet:Entity = getEntityById( HELMET );
			var motionThreshold:MotionThreshold = helmet.get( MotionThreshold );
			motionThreshold.operator = "==";
			motionThreshold.threshold = 0;
			motionThreshold.entered.removeAll();
			motionThreshold.entered.add( helmetDoneMotion );
			
			SceneUtil.setCameraTarget( this, player, false, .02 ); 
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "object_toss_01.mp3" );
		}
		
		private function helmetDoneMotion():void
		{
			var helmet:Entity = getEntityById( HELMET );
			var creator:SceneItemCreator = new SceneItemCreator();
			creator.make( helmet );
			
			SceneUtil.lockInput( this, false );
			
			shellApi.triggerEvent( _events.THORLAK_FRAMED, true );
			shellApi.removeItem( _events.GOBLET );	
			SceneUtil.setCameraTarget( this, player, false, .2 ); 
			
			var erik:Entity = getEntityById( ERIK );
			var clip:MovieClip = Display( erik.get( Display )).displayObject as MovieClip;
			clip.mouseChildren = false;
			clip.mouseEnabled = false;
			
			InteractionCreator.addToEntity( erik, [ InteractionCreator.CLICK ]);
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.reached.add( betrayedMe );
			erik.add( sceneInteraction );
			ToolTipCreator.addToEntity( erik );
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "metal_impact_21.mp3" );
		}
		
		private function betrayedMe( player:Entity, erik:Entity ):void
		{
			var dialog:Dialog = erik.get( Dialog );
			dialog.sayCurrent();
		}
		
		// VIKING UNDERLING LOGIC
		private function doneGrumbling( dialogData:DialogData, triggerErik:Boolean = false ):void
		{
			CharUtils.setDirection( getEntityById( dialogData.entityID), false );
			if( !triggerErik )
			{
				SceneUtil.lockInput( this, false );
			}
			else
			{
				shellApi.triggerEvent( _events.ERIK_TURNS );
			}
		}
		
		override protected function approachViking(player:Entity, viking:Entity):void
		{
			super.approachViking( player, viking );
			var spatial:Spatial = viking.get( Spatial );
			var dialog:Dialog = viking.get( Dialog );
			dialog.faceSpeaker = true;
			
			CharUtils.moveToTarget( player, spatial.x + 100, spatial.y, false, Command.create( giveDrink, viking ), new Point( 30, 100 ));
		}
		
		override protected function giveDrink( player:Entity, viking:Entity ):Boolean
		{
			CharUtils.setDirection( player, false );
			var dialog:Dialog = viking.get( Dialog );
			var triggerErik:Boolean = false;
			
			if( !shellApi.checkEvent( _events.HOLDING_TRAY ))
			{
				dialog.sayById( "grumble" );
				dialog.complete.addOnce( Command.create( doneGrumbling, true  ));
			}
			else
			{ 
				var gotDialog:Boolean = super.giveDrink( player, viking );
				var vikingId:Id = viking.get( Id );
				var nextVikingNumber:Number = DataUtils.getNumber( vikingId.id.substr( vikingId.id.length - 1, vikingId.id.length ));
				if( nextVikingNumber )
				{
					if( !gotDialog )
					{
						nextVikingNumber ++;
						
						var nextViking:Entity = ( nextVikingNumber == 4 ) ? getEntityById( THORLAK ) : getEntityById( UNDERLING + nextVikingNumber );
						
						// ADD SCENE INTERACTIONS BACK AND RESET THRESHOLD
						var sceneInteraction:SceneInteraction = new SceneInteraction();
						
						sceneInteraction.minTargetDelta = new Point( 100, 100 );
						sceneInteraction.reached.add( approachViking );
						
						ToolTipCreator.addToEntity( nextViking );
						InteractionCreator.addToEntity( nextViking, [ InteractionCreator.CLICK ]);
						nextViking.add( sceneInteraction );
						
						var threshold:Threshold = player.get( Threshold );
						threshold.target = nextViking.get( Spatial );
						threshold.entered.removeAll();
						threshold.entered.add( Command.create( approachViking, player, nextViking ));
					}
					
					if( !shellApi.checkEvent( _events.HOLDING_TRAY ))
					{ 
						triggerErik = true;
					}
				}
				else
				{
					triggerErik = true;
				}
				
				if( !gotDialog )
				{		
					dialog.sayById( "thanks" );
				}
				dialog.complete.addOnce( Command.create( doneGrumbling, triggerErik ));
			}
			
			return true;
		}
		
		override protected function hideGobletTray( didNotHandDrink:Boolean = true ):void
		{
			super.hideGobletTray();
			shellApi.triggerEvent( _events.ERIK_TURNS );
		}
	}
}