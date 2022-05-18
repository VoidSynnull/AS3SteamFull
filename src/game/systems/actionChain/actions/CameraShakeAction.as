package game.systems.actionChain.actions
{
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.components.motion.ShakeMotion;
	import game.data.TimedEvent;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.actionChain.ActionCommand;
	import game.systems.motion.ShakeMotionSystem;
	import game.util.SceneUtil;
	
	import org.flintparticles.twoD.zones.DiscZone;
	
	// Shake the camera to simulate an earthquake
	public class CameraShakeAction extends ActionCommand 
	{
		private var _callback:Function;
		private var _time:Number;
		private var _offset:Number;
		private var _camera:Entity;
		
		/**
		 * Camera shake animation
		 * @param time				Length of time for animation in seconds 
		 * @param offset			Shaking offset in pixels (default is 2.5)
		 */
		public function CameraShakeAction(time:Number, offset:Number = 2.5)
		{
			_time = time;
			_offset = offset;
		}
		
		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void
		{
			// remember callback
			_callback = callback;
			
			// add shake to camera
			_camera = group.getEntityById("camera");
			_camera.add( new ShakeMotion(  new DiscZone( null, _offset ) ) );
			ShakeMotionSystem( group.addSystem( new ShakeMotionSystem() )).configEntity( _camera );
			
			// set timer
			SceneUtil.addTimedEvent(group, new TimedEvent(_time, 1, shakingFinished));
		}
		
		/**
		 * When shaking finished 
		 */
		private function shakingFinished():void
		{
			// remove ShakeMotion from camera
			_camera.remove(ShakeMotion);
			_callback();
		}
	}
}
