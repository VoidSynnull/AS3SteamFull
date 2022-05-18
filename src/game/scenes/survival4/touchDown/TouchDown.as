package game.scenes.survival4.touchDown
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.systems.MotionSystem;
	
	import fl.motion.easing.Quadratic;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Children;
	import game.components.entity.character.Character;
	import game.components.motion.Threshold;
	import game.components.timeline.Timeline;
	import game.data.animation.entity.character.PourPitcher;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Walk;
	import game.data.animation.entity.character.Wave;
	import game.scene.template.AudioGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.CutScene;
	import game.scenes.survival4.Survival4Events;
	import game.scenes.survival4.mainHall.MainHall;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.BoundsCheckSystem;
	import game.systems.motion.PositionSmoothingSystem;
	import game.systems.motion.ThresholdSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	
	public class TouchDown extends CutScene
	{
		private var _audioGroup:AudioGroup;
		private var _sceneAudio:Audio;
		
		private var _vanBuren:Entity;
		private var _sceneTimeline:Timeline;
		private var _characterContainerEntity:Entity;
		private var _mansionApproachEntity:Entity;
		private var _charGroup:CharacterGroup;
		private var panTheScene:Boolean = false;
		
		private var _door:Timeline;
		
		private const HELICOPTER:String = 	"helicopter_loop_01.mp3";
		
		private const DISTANCE_TO_HOUSE:int = 850;
		private const TRAVEL_TIME_TO_HOUSE:int = 7;
		private const GROUND_LEVEL:int = 500;
		private const PLANK_DISTANCE:int = 45;
		
		public function TouchDown()
		{
			super();
			configData("scenes/survival4/touchDown/", Survival4Events( events ).TOUCHED_DOWN );
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			SceneUtil.removeIslandParts(this);
			super.init(container);
		}
		
		override public function load():void
		{
			if( shellApi.checkEvent( completeEvent ))
			{
				shellApi.loadScene( MainHall, 80, 980, "right" );
				return;
			}
			super.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			_characterContainerEntity = EntityUtils.createSpatialEntity( this, screen.foreground.container );
			_characterContainerEntity.add( new Tween());
			
			_mansionApproachEntity = EntityUtils.createSpatialEntity( this, screen.foreground.mansionContainer );
			_mansionApproachEntity.add( new Tween());
			
			_sceneTimeline = super.sceneEntity.get( Timeline );
			
			sceneAudio.play( SoundManager.EFFECTS_PATH + HELICOPTER, true );
		}		
		
		override public function setUpCharacters():void
		{
			_vanBuren = getEntityById("van buren");
			_vanBuren.add( new Threshold()).add( new Tween());
			
			setEntityContainer(_vanBuren, screen.copter.door.characterContainer, -10, 0);
			
			Display(_vanBuren.get( Display )).displayObject.transform.colorTransform = new ColorTransform( 0, 0, 0, 1, 17, 28, 27 );
			
			CharUtils.setDirection(player, true);
			CharUtils.setDirection(_vanBuren, true);
			
			Spatial(player.get(Spatial)).scale *= .75;
			Spatial(_vanBuren.get(Spatial)).scale *= .75;
			
			player.add( new Threshold()).add( new Tween());
			
			setEntityContainer(player, screen.copter.door.characterContainer, -20, 0);
			Display(player.get( Display )).displayObject.transform.colorTransform = new ColorTransform( 0, 0, 0, 1, 17, 28, 27 );
			
			_charGroup = super.getGroupById( CharacterGroup.GROUP_ID ) as CharacterGroup;
			//charGroup.removeFSM(player);
			//player.remove(Motion);
			
			addSystem( new MotionSystem(), SystemPriorities.move );
			addSystem( new PositionSmoothingSystem(), SystemPriorities.preRender);
			
			addSystem(new BoundsCheckSystem(), SystemPriorities.resolveCollisions);
			addSystem( new ThresholdSystem(), SystemPriorities.update );
			
			start();
			_door = Children(sceneEntity.get(Children)).getChildByName("door").get(Timeline);
			_door.gotoAndStop(0);
		}
		
		override public function onLabelReached( label:String ):void
		{
			var currentPoint:Point = new Point();
			var display:Display;
			var motion:Motion;
			var spatial:Spatial;
			var threshold:Threshold;
			var tween:Tween; 
			
			switch( label )
			{
				case "triggerDoor":
					_door.gotoAndPlay(2);
					shellApi.triggerEvent(label);
					break;
				
				case "vBStart":
					CharUtils.setAnim( _vanBuren, Walk );
					spatial = _vanBuren.get( Spatial );
					
					tween = _vanBuren.get( Tween );
					if( !tween )
					{
						tween = new Tween();
						_vanBuren.add( tween );
					}
					tween.to( spatial, 1, { x : spatial.x + PLANK_DISTANCE, ease : Quadratic.easeIn, onComplete : vanBurenJumps });
					break;

				case "choperGone":
					sceneAudio.fade( HELICOPTER,0 );
					_sceneTimeline.stop();
					break;
				
				case "enterMansion":
					_sceneTimeline.stop();
					break;
			}
		}
		
		private function vanBurenJumps():void
		{
			setEntityContainer(_vanBuren, screen.foreground.container, PLANK_DISTANCE,0, true);
			
			var threshold:Threshold = _vanBuren.get( Threshold );
			threshold.property = "y";
			threshold.operator = ">=";
			threshold.threshold = GROUND_LEVEL - 100;
			threshold.entered.addOnce( stuckTheLanding );
			
			_charGroup.addFSM( _vanBuren );
			var motion:Motion = _vanBuren.get(Motion);
			motion.acceleration.y = MotionUtils.GRAVITY;
			
			CharUtils.setAnim( player, Walk );
			var spatial:Spatial = player.get( Spatial );
			spatial.x = -20;
			spatial.y = 0;
			
			var tween:Tween = player.get( Tween );
			tween.to( spatial, 1, { x : spatial.x + PLANK_DISTANCE, ease : Quadratic.easeIn, onComplete : playerJumps });
		}
		
		private function playerJumps():void
		{
			setEntityContainer(player, screen.foreground.container, PLANK_DISTANCE,0, true);
			
			var threshold:Threshold = player.get( Threshold );
			threshold.property = "y";
			threshold.operator = ">=";
			threshold.threshold = GROUND_LEVEL - 100;
			threshold.entered.addOnce( playerStuckTheLanding );
			
			_charGroup.addFSM( player );
			var motion:Motion = player.get(Motion);
			motion.acceleration.y = MotionUtils.GRAVITY;
		}
		
		private function stuckTheLanding():void
		{
			CharUtils.setAnim( _vanBuren, Walk );
			var spatial:Spatial = _vanBuren.get( Spatial );
			
			var tween:Tween = _vanBuren.get( Tween );
			tween.to( spatial, 1.5, { x : spatial.x + 100, ease : Quadratic.easeOut, onComplete : vanBurenTurns });
		}
		
		private function playerStuckTheLanding():void
		{
			var fsmControl:FSMControl = player.get( FSMControl );
			fsmControl.setState( CharacterState.WALK );
			
			var spatial:Spatial = player.get( Spatial );
			
			var tween:Tween = player.get( Tween );
			tween.to( spatial, 1, { x : spatial.x + 40 });
		}
		
		// WALKING DOWN THE HILL LOGIC
		private function vanBurenTurns():void
		{
			var fsmControl:FSMControl = _vanBuren.get( FSMControl );
			fsmControl.setState( CharacterState.STAND );
			
			CharUtils.setDirection( _vanBuren, false );
			
			CharUtils.setAnim( _vanBuren, Wave );
			
			CharUtils.setAnim( player, Stand );
			
			var timeline:Timeline = _vanBuren.get( Timeline );
			timeline.labelReached.add( vanBurenHandler );
		}
		
		private function vanBurenHandler( label:String ):void
		{
			var spatial:Spatial = _vanBuren.get( Spatial );
			var timeline:Timeline = _vanBuren.get( Timeline );
			var tween:Tween = _vanBuren.get( Tween );
			
			if( label == "ending" )
			{
				if( !panTheScene )
				{
					CharUtils.setDirection( _vanBuren, true );
					CharUtils.setAnim( _vanBuren, PourPitcher );
				}
				
				else
				{
					timeline.labelReached.removeAll();
					CharUtils.setAnim( _vanBuren, Walk );
					CharUtils.setDirection( _vanBuren, true );
					CharUtils.setAnim( player, Walk );
					CharUtils.setDirection( player, true );
					
					tween.to( spatial, TRAVEL_TIME_TO_HOUSE, { x : spatial.x + DISTANCE_TO_HOUSE, ease : Quadratic.easeInOut }); // ease : Quadratic.easeIn, 
					
					spatial = player.get( Spatial );
					tween = player.get( Tween );
					
					tween.to( spatial, TRAVEL_TIME_TO_HOUSE, { x : spatial.x + DISTANCE_TO_HOUSE, ease : Quadratic.easeInOut });
					
					tween = _characterContainerEntity.get( Tween );
					spatial = _characterContainerEntity.get( Spatial );
					
					tween.to( spatial, TRAVEL_TIME_TO_HOUSE, { y : spatial.y + 130, ease : Quadratic.easeInOut, onComplete : finalDescent });
				}
			}
				
			if( label == "pourPitcher" )
			{
				panTheScene = true;
				_sceneTimeline.play();
			}
		}
		
		private function finalDescent():void
		{
			var spatial:Spatial = _mansionApproachEntity.get( Spatial );
			spatial.x = Spatial( _characterContainerEntity.get( Spatial )).x;
			spatial.y = Spatial( _characterContainerEntity.get( Spatial ) ).y;
			
			setEntityContainer(player, screen.foreground.mansionContainer);
			
			setEntityContainer(_vanBuren, screen.foreground.mansionContainer);
			
			var tween:Tween = player.get( Tween );
			spatial = player.get( Spatial );
			tween.to( spatial, 3, { x : spatial.x + 20, scale : spatial.scale * .75 });
			
			tween = _vanBuren.get( Tween );
			spatial = _vanBuren.get( Spatial );
			tween.to( spatial, 3, { x : spatial.x + 20, scale : spatial.scale * .75 });
			
			tween = _mansionApproachEntity.get( Tween );
			spatial = _mansionApproachEntity.get( Spatial );
			
			tween.to( spatial, 5, { y : spatial.y + 120, ease : Quadratic.easeIn, onComplete : enterTheHouse });
		}

		private function enterTheHouse():void
		{
			SceneUtil.lockInput( this, false );
			var introPopup:DialogPicturePopup = new DialogPicturePopup( overlayContainer );
			introPopup.updateText("after days in the woods, you've been rescued. but something's not right...", "start");
			introPopup.configData("introPopup.swf", "scenes/survival4/touchDown/");
			introPopup.popupRemoved.addOnce(introPopupClosed);
			addChildGroup(introPopup);
		}
		
		private function bitmapSceneElements( string:String ):void
		{
			var clip:MovieClip = screen[string]["content"];
			DisplayUtils.convertToBitmapSprite( clip, null, 2 );
		}
		
		private function introPopupClosed():void
		{
			shellApi.completeEvent( completeEvent );
			shellApi.loadScene( MainHall, 80, 980, "right" );
		}
	}
}