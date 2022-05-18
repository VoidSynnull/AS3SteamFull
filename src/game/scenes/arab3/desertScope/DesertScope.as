package game.scenes.arab3.desertScope
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Camera;
	import engine.components.Display;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.input.Input;
	import game.components.motion.FollowTarget;
	import game.components.timeline.Timeline;
	import game.components.ui.Cursor;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Celebrate;
	import game.data.animation.entity.character.DanceMoves01;
	import game.data.animation.entity.character.RobotDance;
	import game.data.ui.ToolTipType;
	import game.scene.template.AudioGroup;
	import game.scene.template.CameraGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.arab1.desertScope.components.WatchThief;
	import game.scenes.arab1.desertScope.systems.WatchThiefSystem;
	import game.scenes.arab3.Arab3Events;
	import game.scenes.arab3.bazaar.Bazaar;
	import game.scenes.arab3.shared.SmokePuffGroup;
	import game.systems.SystemPriorities;
	import game.systems.TimerSystem;
	import game.systems.motion.DestinationSystem;
	import game.systems.ui.NavigationArrowSystem;
	import game.systems.ui.TextDisplaySystem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	
	public class DesertScope extends PlatformerGameScene
	{
		private var _events:Arab3Events;
		private const SCOPE_RADIUS:int = 243;
		private var _camTarg:Entity;
		private var _followTarget:FollowTarget;
		private var _jinn:Entity;
		private var _smokePuffGroup:SmokePuffGroup;
		private var _target:Entity;
		
		public function DesertScope()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/arab3/desertScope/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override protected function addBaseSystems():void
		{
			super.addBaseSystems();
			
			super.addSystem(new DestinationSystem(), SystemPriorities.update);
			super.addSystem(new TextDisplaySystem(), SystemPriorities.update);
			super.addSystem(new NavigationArrowSystem(), SystemPriorities.update);
			super.addSystem(new TimerSystem(), SystemPriorities.update);
		}
		
		override protected function addGroups():void
		{
			// This group holds a reference to the parsed sound.xml data and can be used to setup an entity with its sound assets if they are defined for it in the xml.
			var audioGroup:AudioGroup = addAudio();
			
			addCamera();
			addCollisions(audioGroup);
			addCharacters();
			addCharacterDialog(this.uiLayer);
			addDoors(audioGroup);
			addItems();
			addPhotos();
			addBaseSystems();
		}
		
		
		// all assets ready
		override public function loaded():void
		{
			_events = new Arab3Events;
						
			setupScope();
			hidePlayer();
			setupMovement();
			setupCloseButton();
			
			if( shellApi.checkEvent( _events.GENIE_IN_DESERT_SKY ) && !shellApi.checkEvent( _events.GENIE_IN_ATRIUM ))
			{
				setupNPCs();
			}
			else
			{
				super.loaded();
				removeEntity( this.getEntityById( "jinn" ));
				Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.TARGET;
			}
		}
		
		private function setupMovement():void
		{	
			// resize camera bounds
			var widthBuffer:int;
			var heightBuffer:int;
			
			if(PlatformUtils.isMobileOS)
			{
				widthBuffer = super.shellApi.viewportWidth/2 - (SCOPE_RADIUS * 1.3);
				heightBuffer = super.shellApi.viewportHeight/2 - (SCOPE_RADIUS * 1.5); // temp fix to remove the edges being visible on some mobile devices
			} 
			else 
			{
				widthBuffer = super.shellApi.viewportWidth/2 - SCOPE_RADIUS;
				heightBuffer = super.shellApi.viewportHeight/2 - SCOPE_RADIUS;
			}
			
			var camera:Camera = super.shellApi.camera.camera;
			camera.resize( shellApi.viewportWidth, shellApi.viewportHeight, camera.areaWidth + widthBuffer * 2, camera.areaHeight + heightBuffer * 2, -widthBuffer , -heightBuffer );
			
			// map input system to move camera
			_camTarg = EntityUtils.createMovingEntity(this, _hitContainer["camTarg"], _hitContainer);
			_camTarg.add( new MotionBounds( new Rectangle(250,250,2254,443)));
			Display(_camTarg.get(Display)).visible = false;
			
			_followTarget = new FollowTarget();
			_followTarget.target = shellApi.inputEntity.get( Spatial );	// the Spatial that will be followed, in this case the main input.
			_followTarget.rate = 0.02;	// rate of target following, 1 is highest causing 1:1 following 
			_followTarget.applyCameraOffset = true;	// this needs be true with scenes using the camera 
			
			( super.getGroupById("cameraGroup") as CameraGroup).setTarget(_camTarg.get(Spatial), true);
			
			var input:Input = SceneUtil.getInput( this );
			input.inputDown.add( onInputDown );
			input.inputUp.add( onInputUp );
			
		}
		
		private function hidePlayer():void
		{
			// removing the player from the scene XML was causing problems when you load in from another scene
			CharUtils.lockControls(player);
			Display(player.get(Display)).visible = false;
		}
		
		private function setupNPCs():void
		{
			_jinn = this.getEntityById( "jinn" );
			EntityUtils.removeInteraction( _jinn );
			
//			if( shellApi.checkEvent( _events.GENIE_IN_DESERT_SKY ) && !shellApi.checkEvent( _events.GENIE_IN_ATRIUM ))
//			{
				_target					 	=	new Entity();
				var jinnSpatial:Spatial 	=	_jinn.get( Spatial );
				var spatial:Spatial 		=	new Spatial( jinnSpatial.x, jinnSpatial.y );
				
				_target.add( spatial );
				addEntity( _target );
				
				_jinn.add( new WatchThief());
				addSystem( new WatchThiefSystem( getEntityById( "camera" ), spottedJinn ));
				
				_smokePuffGroup = addChildGroup( new SmokePuffGroup()) as SmokePuffGroup;
				_smokePuffGroup.initJinnSmoke( this, _hitContainer );
				_smokePuffGroup.smokeLoadCompleted.addOnce( smokeReady );
				
				Timeline( _jinn.get( Timeline )).handleLabel( "ending", handleLabel );//, false );
		//		Timeline( _jinn.get( Timeline )).handleLabel( "stand", handleLabel, false );
//			}
//			else
//			{
//				removeEntity( _jinn );
//			}
		}
		
		private function smokeReady():void
		{
			_smokePuffGroup.addJinnTailSmoke( _jinn );
			super.loaded();
			Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.TARGET;
		}
		
		private function handleLabel():void
		{
			var spellChance:int = Math.round( GeomUtils.randomInRange( 0, 10 ));
		////	if( spellChance <= 2 )
		//	{
		//		Timeline( _jinn.get( Timeline )).removeLabelHandler( resetLabelAfterCast );
		//		Timeline( _jinn.get( Timeline )).labelReached.removeAll();
		//		Timeline( _jinn.get( Timeline )).handleLabel( "ending", castSpell );
		//		
		//		_smokePuffGroup.startSpellCasting( _jinn );
		//		Timeline( _jinn.get( Timeline )).handleLabel( "stand", handleLabel, false );
		//	}
		//	else
		//	{
				if( spellChance <= 4 )
				{
					CharUtils.setAnim( _jinn, Celebrate );
					Timeline( _jinn.get( Timeline )).handleLabel( "ending", resetLabel );
				}
				else if( spellChance <= 6 )
				{
					CharUtils.setAnim( _jinn, DanceMoves01 );
					Timeline( _jinn.get( Timeline )).handleLabel( "ending", resetLabel );
				}
				else
				{
					CharUtils.setAnim( _jinn, RobotDance );
					Timeline( _jinn.get( Timeline )).handleLabel( "ending", resetLabel );
				}
		//	}
		}
		
	//	private function castSpell():void
	////	{
	//		trace();
	//		
	////		Timeline( _jinn.get( Timeline )).removeLabelHandler( castSpell );
	//		Timeline( _jinn.get( Timeline )).labelReached.removeAll();
	//		_smokePuffGroup.castSpell( _jinn, new <Entity>[ _target ], null, resetLabelAfterCast, false, true );
	//	}
		
		private function resetLabel():void
		{
			Timeline( _jinn.get( Timeline )).handleLabel( "stand", handleLabel );
//			if( label == "robotDance" || label == "danceMoves01" || label == "celebrate" )
//			{
//				Timeline( _jinn.get( Timeline )).labelReached.removeAll();
//				Timeline( _jinn.get( Timeline )).handleLabel( "stand", handleLabel );//, false );
//			}
//			if( label == "stand" )
//			{
//				Timeline( _jinn.get( Timeline )).removeLabelHandler( resetLabel );
//				Timeline( _jinn.get( Timeline )).labelReached.removeAll();
//				handleLabel();
//			}
		}
		
	//	private function resetLabelAfterCast():void
	//	{
	//		Timeline( _jinn.get( Timeline )).handleLabel( "beginning", handleLabel );//, false );			
	//	}
		
		private function onInputDown( input:Input ):void
		{
			_camTarg.add( _followTarget );
		}
		
		private function onInputUp( input:Input ):void
		{
			_camTarg.remove( FollowTarget );
		}
		
		private function setupScope():void
		{
			var scope:Sprite = this._hitContainer["scope"];
			scope.x = shellApi.camera.viewportWidth*0.5;
			scope.y = shellApi.camera.viewportHeight*0.5;
			
//			if( shellApi.camera )
//			{
//				var width:Number = shellApi.camera.viewportWidth;
//				var height:Number = shellApi.camera.viewportHeight;
//				var scale:Number;
//				
//				if( shellApi.viewportScale != 1 )
//				{
//					scale = 1 - shellApi.viewportScale;
//					
//					scope.width += width * scale;
//					scope.height += height * scale;
//				}
//				
//				if( shellApi.camera.scale != 1 )
//				{
//					scale = 1 - shellApi.camera.scale;
//					
//					scope.width += width * scale;
//					scope.height += height * scale;
//				}
//			}
			
			BitmapUtils.createBitmap(scope);
			
			this.overlayContainer.addChild(scope);
		}
		
		private function setupCloseButton():void
		{
			ButtonCreator.loadCloseButton( this, this.overlayContainer, onClose );
		}
		
		private function onClose(...p):void
		{
			this.shellApi.loadScene( Bazaar, 3200 , 425, "right" );
		}
		
		public function spottedJinn():void
		{
			SceneUtil.lockInput( this );
			
			_camTarg.add( new FollowTarget( _jinn.get( Spatial )));
			shellApi.completeEvent( _events.USED_SPYGLASS );
			_jinn.remove( WatchThief );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, unlockInput ));
		}
		
		private function unlockInput():void
		{
			SceneUtil.lockInput( this, false );
		}
	}
}