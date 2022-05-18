package game.scenes.deepDive3.shared.creators
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.group.Group;
	import engine.managers.SoundManager;
	
	import game.components.animation.FSMControl;
	import game.components.animation.FSMMaster;
	import game.components.motion.Edge;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionControlBase;
	import game.components.motion.MotionTarget;
	import game.components.motion.Navigation;
	import game.components.motion.WaveMotion;
	import game.creators.animation.FSMStateCreator;
	import game.data.WaveMotionData;
	import game.scenes.deepDive3.shared.components.Drone;
	import game.scenes.deepDive3.shared.drone.states.DroneFollowState;
	import game.scenes.deepDive3.shared.drone.states.DroneIdleState;
	import game.scenes.deepDive3.shared.drone.states.DroneMovetoState;
	import game.scenes.deepDive3.shared.drone.states.DroneNeanderState;
	import game.scenes.deepDive3.shared.drone.states.DroneScanState;
	import game.scenes.deepDive3.shared.drone.states.DroneSleepState;
	import game.scenes.deepDive3.shared.drone.states.DroneState;
	import game.scenes.deepDive3.shared.drone.states.DroneWakeState;
	import game.scenes.deepDive3.shared.nodes.DroneNode;
	import game.util.AudioUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;

	public class DroneCreator
	{
		public function DroneCreator()
		{
		}
		
		public static function create(clip:DisplayObjectContainer, container:DisplayObjectContainer, group:Group, initialState:String, spawnAt:Spatial = null):Entity
		{
			if(!container.contains(clip)){
				container.addChild(clip);
			}
			DisplayUtils.convertToBitmapSprite(clip["light"], null, 1, true, clip["light"]);
			//DisplayUtils.convertToBitmap(clip["language"]);
			DisplayUtils.convertToBitmap(clip["body"]);
			
			var drone:Entity = EntityUtils.createMovingEntity(group, clip, container);
			
			if(spawnAt){
				Spatial(drone.get(Spatial)).x = spawnAt.x;
				Spatial(drone.get(Spatial)).y = spawnAt.y;
			}
			
			var droneComponent:Drone = new Drone();
			droneComponent.bounds = group.shellApi.currentScene.sceneData.bounds;
			droneComponent.targetSpatial = group.shellApi.player.get(Spatial);
			droneComponent.lookAtSpatial = group.shellApi.player.get(Spatial);
			
			drone.add(droneComponent);
			drone.add(new Tween());

			var edge:Edge = new Edge( EDGE_RADIUS, EDGE_RADIUS, EDGE_RADIUS, EDGE_RADIUS);

			drone.add(new Edge());
			drone.add(new MotionControl());
			
			var motionControlBase:MotionControlBase = new MotionControlBase();
			
			drone.add(motionControlBase);
			
			drone.add(new MotionTarget());
			drone.add(new SpatialAddition());
			drone.add(new Navigation());
			if(Display(drone.get(Display)).displayObject["language"]){
				Display(drone.get(Display)).displayObject["language"].visible = false;
			}
			
			var stateCreator:FSMStateCreator = new FSMStateCreator();
			
			var fsmControl:FSMControl = new FSMControl(group.shellApi);
			drone.add(fsmControl);
			drone.add(new FSMMaster());
			
			stateCreator.createStateSet(new <Class>[DroneSleepState, DroneWakeState, DroneIdleState, DroneFollowState, DroneMovetoState, DroneScanState, DroneNeanderState], drone, DroneNode);
			
			fsmControl.setState(initialState);
			
			if(initialState != DroneState.SLEEP){
				
				var waveMotionData:WaveMotionData = new WaveMotionData("y", 6, .07);
				var waveMotion:WaveMotion = new WaveMotion();
				waveMotion.add(waveMotionData);
				drone.add(waveMotion);
				
				AudioUtils.playSoundFromEntity(drone, SoundManager.EFFECTS_PATH+"alien_drone_loop.mp3", 400, 0, 1, Quad.easeInOut);
				
			}
			
			trace("DRONE CREATED!");

			return drone;
		}
		
		private static const EDGE_RADIUS:int = 70;
	}
}