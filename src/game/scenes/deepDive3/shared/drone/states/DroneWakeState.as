package game.scenes.deepDive3.shared.drone.states
{
	import com.greensock.easing.Quad;
	
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import engine.managers.SoundManager;
	
	import game.components.entity.Sleep;
	import game.components.motion.WaveMotion;
	import game.data.WaveMotionData;
	import game.util.AudioUtils;

	public class DroneWakeState extends DroneState
	{
		public function DroneWakeState()
		{
			super.type = "wake";
		}
		
		override public function start():void
		{
			this._node.entity.remove(Sleep);
			node.drone.stateChange.dispatch(super.type);
			wakeUp();
		}
		
		override public function update(time:Number):void
		{
			//trace("wake");
		}
		
		private function wakeUp():void{
			// blink light a bit to show some life
			var light:Sprite = node.display.displayObject["light"] as Sprite;
			node.tween.to(light, 0.3, {delay:0.7, alpha:0.4, yoyo:true, repeat:2, onComplete:turnOnLight});
		}
		
		private function turnOnLight():void{
			var light:Sprite = node.display.displayObject["light"] as Sprite;
			node.tween.to(light, 0.6, {alpha:0.6, onComplete:getUp});
			
			AudioUtils.playSoundFromEntity(node.entity, SoundManager.EFFECTS_PATH+"alien_drone_loop.mp3", 400, 0, 1, Quad.easeInOut);
		}
		
		private function getUp():void{
			// wiggle to proper rotation
			node.tween.to(node.spatial, 1, {rotation:0, onComplete:toIdle});
			
			// move up slightly
			node.motion.acceleration = new Point(-60,-100);
		}
		
		private function toIdle():void{
			node.motion.friction = new Point(100,100);
			node.motion.zeroAcceleration();
			
			var waveMotionData:WaveMotionData = new WaveMotionData("y", 6, .07);
			var waveMotion:WaveMotion = new WaveMotion();
			waveMotion.add(waveMotionData);
			node.entity.add(waveMotion);
			node.fsmControl.setState("idle");
		}
	}
}