package game.scenes.deepDive3.shared
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.systems.TweenSystem;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.motion.FollowTarget;
	import game.components.timeline.Timeline;
	import game.scenes.deepDive1.shared.SubScene;
	import game.scenes.deepDive3.shared.components.Drone;
	import game.scenes.deepDive3.shared.creators.DroneCreator;
	import game.systems.SystemPriorities;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	public class DroneGroup extends Group
	{
		public function DroneGroup(scene:SubScene, container:DisplayObjectContainer)
		{
			_container = container;
			_scene = scene;
		}
		
		override public function added():void
		{
			super.addSystem(new WaveMotionSystem(), SystemPriorities.move);
			super.addSystem(new FollowTargetSystem(), SystemPriorities.move);
			super.addSystem(new WaveMotionSystem(), SystemPriorities.move);
			super.addSystem(new TweenSystem(), SystemPriorities.move);
		}
		
		/**
		 * Converts a clip in the scene into a drone.
		 * @param	clip : clip for the drone
		 * @param	initialState : which state the drone should start in - default is idle
		 * @param	spawnAt : a custom spatial for the newly created drone to "spawn" at creation.
		 */
		public function makeDrone(clip:DisplayObjectContainer, initialState:String = "idle", spawnAt:Spatial = null):Entity{
			var drone:Entity = DroneCreator.create( clip, _container, this, initialState, spawnAt );
			drones.push(drone);
			
			// if quality is high, create scan effect
			if(PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_HIGH){
				if(scanEffect == null){
					this.shellApi.loadFile(this.shellApi.assetPrefix + "scenes/deepDive3/shared/drone_scan.swf", makeScanEffect);
				}
				
				Drone(drone.get(Drone)).scanPlayer.add(scanPlayerEffect);
			}
			
			if(drones.length == _dronesToMake){
				dronesCreated.dispatch(_dronesToMake);
			}
			
			return drone;
		}
		
		private function scanPlayerEffect():void{
			if(scanEffect){
				var timelineEntity:Entity = Children(scanEffect.get(Children)).children[0];
				Timeline(timelineEntity.get(Timeline)).gotoAndPlay("scan");
				_scene.shellApi.triggerEvent("alienScan");
			}
		}
		
		private function makeScanEffect(clip:DisplayObjectContainer):void{
			scanEffect = EntityUtils.createSpatialEntity(this, clip, _container);
			TimelineUtils.convertClip(clip as MovieClip, this, null, scanEffect, true);
			scanEffect.add(new Id("scanEffect"));
			scanEffect.add(new FollowTarget(_scene.shellApi.player.get(Spatial)));
		}
		
		/**
		 * Creates drones to mill about in your scene.
		 * @param	number : how many drones to create - default set to 2.
		 * @param	spawnSpatials : a vector of custom spatials for the drones to "spawn" at.  If null, drones spawn at 0,0
		 */
		public function createSceneDrones(number:int = 1, spawnSpatials:Vector.<Spatial> = null, initialState:String = "neander"):void{
			// creates drones from a pulled movieClip - 
			for(var c:int = 1; c <= number; c++){
				_dronesToMake++;
				if(spawnSpatials != null){
					this.shellApi.loadFile(this.shellApi.assetPrefix + "scenes/deepDive3/shared/drone.swf", Command.create(makeDrone, initialState, spawnSpatials[c-1]));
				} else {
					this.shellApi.loadFile(this.shellApi.assetPrefix + "scenes/deepDive3/shared/drone.swf", Command.create(makeDrone, initialState));
				}
			}
			
			// if quality is high, create scan effect
			if(PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_HIGH){
				this.shellApi.loadFile(this.shellApi.assetPrefix + "scenes/deepDive3/shared/drone_scan.swf", makeScanEffect);
			}
		}
		
		/**
		 * Set a vector of spatials for the drones to check out when they neander.  Makes your drones appear interested in certain points in the scene.
		 * @param	spatials : spatials of curious spots for your drones to check out (other than you)
		 */
		public function setNeanderSpatials(spatials:Vector.<Spatial>):void{
			for(var c:int = 0; c < drones.length; c++){
				Drone(drones[c].get(Drone)).neanderSpatials = spatials;
			}
		}
		
		public var drones:Vector.<Entity> = new Vector.<Entity>;
		public var dronesCreated:Signal = new Signal(int);
		
		public var scanEffect:Entity;
		
		private var _container:DisplayObjectContainer;
		private var _scene:SubScene;
		
		private var _dronesToMake:int = 0;
		
		
	}
}