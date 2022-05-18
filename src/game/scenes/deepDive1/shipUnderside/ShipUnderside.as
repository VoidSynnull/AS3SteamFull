package game.scenes.deepDive1.shipUnderside
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.SpatialOffset;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	
	import game.components.entity.Sleep;
	import game.components.hit.Zone;
	import game.components.motion.FollowTarget;
	import game.components.motion.Proximity;
	import game.components.motion.RotateControl;
	import game.components.motion.TargetSpatial;
	import game.components.motion.WaveMotion;
	import game.components.timeline.Timeline;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.scenes.deepDive1.shared.SubScene;
	import game.scenes.deepDive1.shared.components.Filmable;
	import game.scenes.deepDive1.shared.components.SubCamera;
	import game.systems.SystemPriorities;
	import game.systems.motion.ProximitySystem;
	import game.systems.motion.RotateToVelocitySystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	import game.util.Utils;
	
	public class ShipUnderside extends SubScene
	{
		private var _seaDragon:Entity;
		private var _startedTutorial:Boolean = false
		private var _doorReef:Entity;
		private var _notReadyToBeFilmable:Boolean;
		
		private var _pupilSeadragon:Entity;
		
		public function ShipUnderside()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/deepDive1/shipUnderside/";
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();		
			
			var subCamera:SubCamera = super.shellApi.player.get(SubCamera);
			subCamera.angle = 120;
			subCamera.distanceMax = 400;
			subCamera.distanceMin = 0;
			
			// Create seaDragon
			var clip:MovieClip = super._hitContainer["seaDragon"];
			if(!PlatformUtils.inBrowser)
			{
				this.convertContainer(clip);
			}
			
			_seaDragon = EntityUtils.createMovingEntity( this, clip );
			TimelineUtils.convertClip( clip, null, _seaDragon, null, true )
			MotionUtils.addWaveMotion(_seaDragon, new WaveMotionData("y",7,0.1),this);
			
			addEyes (_seaDragon,EntityUtils.getDisplay(_seaDragon).displayObject["head"]["pupilContainer"]["pupil"])
			
			if (!this.shellApi.checkEvent(_events.TUTORIAL_COMPLETE)) {
				var zoneHitEntity:Entity = super.getEntityById("zoneSeaDragon");
				var zoneHit:Zone = zoneHitEntity.get(Zone);
				zoneHit.entered.add(startSeaHorse);
				//zoneHit.exitted.add(stopParticles);
				//zoneHit.inside.add(startParticles);
				zoneHit.shapeHit = false;
				zoneHit.pointHit = true;
				_notReadyToBeFilmable = true
				SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, sayIntro));
			} else {
				removeEntity(_seaDragon)
				_notReadyToBeFilmable = false
			}
			
			setupBgFish()
			
			//	super.addSystem(new FishPathSystem(),SystemPriorities.move);
			super.addSystem(new RotateToVelocitySystem(),SystemPriorities.move);
			super.addSystem(new ProximitySystem());
			super.addSystem(new BackgroundFishSystem());
		}
		
		private function setupBgFish():void {			
			var c:BackgroundFishDir
			
			for(var i:uint=1;i<=19;i++){
				var clip:MovieClip = _hitContainer["sil"+i];
				var e:Entity = new Entity();
				e = TimelineUtils.convertClip( clip, this, e );
				
				var spatial:Spatial = new Spatial();
				spatial.x = clip.x;
				spatial.y = clip.y;
				spatial.scale = Utils.randNumInRange(0.75, 1.25);
				
				e.add(spatial);
				e.add(new Display(clip));
				e.add(new Id("j"+i));
				e.add(new SpatialOffset());
				
				c = new BackgroundFishDir()
				c.direction = Math.random() < .5 ? -1 : 1
				if (c.direction < 1) {
					spatial.scaleX *= -1
				}
				c.speed = Utils.randNumInRange(.7, 2);
				c.min = -100
				c.max = 3300
				e.add(c) 
				
				e.add ( new Sleep(false, true ));
				
				//var waveMotionData:WaveMotionData;
				//waveMotionData = new WaveMotionData("y", 100, .01, i * Math.PI/4);
				//var waveMotion:WaveMotion = new WaveMotion();
				//waveMotion.add(waveMotionData);
				
				//waveMotionData = new WaveMotionData("rotation", 10, .01,"sin", i * Math.PI/4);
				//waveMotion.add(waveMotionData);
				
				//e.add(waveMotion);
				MotionUtils.addWaveMotion(e, new WaveMotionData("y",100,0.01,"sin", i * Math.PI/4),this);
				MotionUtils.addWaveMotion(e, new WaveMotionData("rotation",10,0.01,"sin", i * Math.PI/4),this);
				
				super.addEntity(e);
				e.get(SpatialOffset).y = spatial.y;
			}
		}
		
		public function sayIntro():void
		{
			super.playerSay("subOperation");
		}
		
		private function startSeaHorse(zoneId:String, characterId:String):void{
			trace ("[ShipUnderside] startSeaHorse")
			
			if (_startedTutorial) {
				return
			} else {
				
				_startedTutorial = true
				
				CharUtils.lockControls(this.shellApi.player, true, true);
				SceneUtil.lockInput(this, true);
				
				var sp:Spatial = shellApi.player.get(Spatial)
				var fishSp:Spatial = _seaDragon.get(Spatial)
				_seaDragon.add ( new Sleep(false, true ));
				
				var followTarget:FollowTarget = new FollowTarget();
				followTarget.target = sp
				followTarget.rate = .02
				followTarget.offset = new Point (-100,0)
				_seaDragon.add (followTarget)
				
				Timeline(_seaDragon.get(Timeline)).gotoAndPlay("swim")
				
				var proximity:Proximity = new Proximity(500, sp);
				proximity.entered.addOnce(onSeaDragonNearPlayer);
				_seaDragon.add (proximity)
			}
		}
		
		private function onSeaDragonNearPlayer (e:Entity): void {
			trace ("[ShipUnderside] onSeahorseNearPlayer")
			super.playMessage( "seaHorse" );
			SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, sendSeahorseToYellowCoral));
		}
		
		private function sendSeahorseToYellowCoral():void
		{	
			_seaDragon.remove(FollowTarget)
			_seaDragon.remove(Proximity)
			//SceneUtil.setCameraTarget(this, _seaDragon);
			var speed:Number = (2900 - _seaDragon.get(Spatial).x) / 2900 * 42
			TweenUtils.entityTo(_seaDragon,Spatial,speed,{x:2900,y:1600,onComplete:onSeaDragonReachedYellowCoral});
			SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, returnCameraToPlayer));
		}
		
		private function returnCameraToPlayer():void {
			//SceneUtil.setCameraTarget(this, shellApi.player);
			trace ("[ShipUnderside] onSeaDragonReachedYellowCoral")
			CharUtils.lockControls(this.shellApi.player,false, false);
			SceneUtil.lockInput(this, false);
			
			var interaction:Interaction = InteractionCreator.addToEntity( _seaDragon, [InteractionCreator.UP] );
			interaction.up.add( onSeaDragonClick );
		}
		
		private function onSeaDragonClick (...p):void {
			sendSeahorseToRedCoral()
		}
		
		private function onSeaDragonReachedYellowCoral():void {
			//			var sp:Spatial = shellApi.player.get(Spatial)
			//			var proximity:Proximity = new Proximity(300, sp);
			//			proximity.entered.addOnce(sendSeahorseToRedCoral);
			//			_seaDragon.add (proximity)
		}
		
		private function sendSeahorseToRedCoral (e:Entity =null): void {
			trace ("[ShipUnderside] onSeahorseNearPlayer2")
			Spatial(_seaDragon.get(Spatial)).scaleX *= -1
			Spatial(_pupilSeadragon.get(Spatial)).scaleX *= -1
			EntityUtils.getDisplay(_seaDragon).displayObject["head"]["pupilContainer"].rotation += 180
			_seaDragon.remove(Tween)
			var sp:Spatial = _seaDragon.get(Spatial)
			var d:Number = Point.distance(new Point (sp.x,sp.y), new Point (450,1750))
			var t:Number =  d / 1000 * 16
			TweenUtils.entityTo(_seaDragon,Spatial,t,{x:450,y:1750});
			super.makeFilmable( _seaDragon, onFishFilmEvent,230, 4, true ); 
		}
		
		private function onSeaDragonReachedRedCoral():void {
			trace ("[ShipUnderside] onSeaDragonReachedRedCoral")
		}
		
		private function onFishFilmEvent( entity:Entity ):void
		{
			// Using this for click if we aren't ready to have it be filmable
			var filmable:Filmable = entity.get(Filmable);
			trace ("[ShipUnderside] onFishFilmedEvent.  filmable.state: " +  filmable.state)
			switch( filmable.state )
			{
				case filmable.FILMING_OUT_OF_RANGE:
				{
					// need to get closer
					super.playMessage( "tooFar" );
					break;
				}
				case filmable.FILMING_BLOCK:
				{
					// explain why
					super.playMessage( "filmBlockSeaHorse" );
					break;
				}
				case filmable.FILMING_START:
				{
					// listen for complete
					super.playMessage( "filmStart" );
					break;
				}
				case filmable.FILMING_STOP:
				{
					// listen for complete
					super.playMessage( "filmStop" );
					break;
				}
				case filmable.FILMING_COMPLETE:
				{
					// listen for complete
					super.playMessage( "filmCompleteSeaHorse", onFishCaptured );
					shellApi.triggerEvent(_events.SEADRAGON_CAPTURED, true);
					super.removeFilmable( _seaDragon)
					break;
				}
				default:
				{
					trace( "invalid state: " + filmable.state );
					break;
				}
			}
		}
		
		private function onFishCaptured ():void {
			trace ("[ShipUnderside] setTutorialComplete")
			// fire complete events
			shellApi.completeEvent(_events.TUTORIAL_COMPLETE)
			shellApi.triggerEvent(_events.TUTORIAL_COMPLETE)
			
			// free seahorse
			TweenUtils.entityTo(_seaDragon,Spatial,37,{x:100,y:100});
			
			// log fish
			super.logFish( _events.SEADRAGON );
		}
		
		private function addEyes(fish:Entity, pupilMC:MovieClip):void
		{
			// Add the pupil and set it up to rotate with the player
			_pupilSeadragon = new Entity();
			_pupilSeadragon.add(new Spatial(pupilMC.x, pupilMC.y));
			_pupilSeadragon.add(new Display(pupilMC));
			_pupilSeadragon.add(new Id("playerEye"));
			_pupilSeadragon.add(new TargetSpatial(this.shellApi.inputEntity.get(Spatial)));
			var rotateControl:RotateControl = new RotateControl();
			rotateControl.origin = fish.get(Spatial);
			rotateControl.targetInLocal = true;
			rotateControl.ease = .3;
			//rotateControl.adjustForViewportScale = true;
			//rotateControl.syncHorizontalFliping = true;
			_pupilSeadragon.add(rotateControl);
			EntityUtils.addParentChild(_pupilSeadragon, fish);
			this.addEntity(_pupilSeadragon);
		}
	}
}