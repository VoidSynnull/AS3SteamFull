package game.scenes.shrink.shared.Systems.CarControlSystem
{
	import engine.managers.SoundManager;
	
	import game.data.sound.SoundType;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class CarControlSystem extends GameSystem
	{
		public function CarControlSystem()
		{
			super(CarControlNode, updateNode);
			super._defaultPriority = SystemPriorities.moveControl;
		}
		
		private const DRIVE_SOUND:String = SoundManager.EFFECTS_PATH + "small_engine_01_loop.mp3";
		
		public function updateNode(node:CarControlNode, time:Number):void
		{
			if(node.controls.moving && node.motion.velocity.x == 0)
			{
				node.audio.stop(DRIVE_SOUND, SoundType.EFFECTS);
				node.controls.moving = false;
			}
			
			if(!node.controls.inCar)
				return;
			
			if(Math.abs(node.motion.velocity.x) > 0 && !node.controls.moving)
			{
				node.audio.play(DRIVE_SOUND, true);
				node.controls.moving = true;
			}
			
			node.audio.setVolume(Math.abs(node.motion.velocity.x) / node.controls.maxSpeed);
			
			if(node.controls.playerMotion != null)
			{
				if(Math.abs(node.controls.playerMotion.velocity.x) > Math.abs(node.motion.velocity.x))
					node.motion.velocity.x = node.controls.playerMotion.velocity.x;
				return;
			}
			if(node.controls.input == null)
				return;
			
			if(!node.controls.input.inputStateDown)
			{
				node.motion.acceleration.x = 0;
				return;
			}
			
			var centerX:Number = node.controls.input.container.width / 2;
			var pos:Number = node.controls.input.target.x - centerX - group.shellApi.camera.x;
			var distance:Number = pos - node.spatial.x;
			
			node.motion.acceleration.x = distance * node.controls.acceleration;
		}
	}
}