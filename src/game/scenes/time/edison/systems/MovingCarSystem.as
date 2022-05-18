package game.scenes.time.edison.systems
{
	import flash.geom.Point;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.time.edison.components.MovingCar;
	import game.scenes.time.edison.nodes.MovingCarNode;
	import game.systems.GameSystem;
	
	import org.osflash.signals.Signal;
	
	public class MovingCarSystem extends GameSystem
	{
		public function MovingCarSystem()
		{
			super(MovingCarNode, updateNode);
		}
		
		private function updateNode(node:MovingCarNode, time:Number):void
		{
			var movingCar:MovingCar = node.movingCar;
			var carDisplay:Display = node.entity.get(Display);
			var carSpatial:Spatial = node.entity.get(Spatial);
			var carMotion:Motion = node.entity.get(Motion);
			var bigWheelMotion:Motion = movingCar.bigWheel.get(Motion);
			var smallWheelMotion:Motion = movingCar.smallWheel.get(Motion);
			var topPlatformMotion:Motion = movingCar.topPlatform.get(Motion);
			var seatPlatformMotion:Motion = movingCar.seatPlatform.get(Motion);
			
			switch(movingCar.state)
			{
				case "stopped":
					carMotion.velocity = new Point(0, 0);
					carMotion.acceleration.x = 0;
					break;
				case "moving":
					carMotion.acceleration.x = movingCar.accel;
					break;
				case "threshold":
					carMotion.acceleration.x = -movingCar.accel*2;
					break;
			}
			
			topPlatformMotion.velocity.x = carMotion.velocity.x;
			seatPlatformMotion.velocity.x = carMotion.velocity.x;
			bigWheelMotion.rotationVelocity = carMotion.velocity.x;
			smallWheelMotion.rotationVelocity = carMotion.velocity.x * 2;
			
			if(carSpatial.x >= movingCar.stopX)
			{
				movingCar.state = "threshold";
				_reachedEnd.dispatch();
			}
			
			if(movingCar.state == "threshold" && carMotion.velocity.x <= 10)
				movingCar.state = "stopped";
		}
		
		public var _reachedEnd:Signal = new Signal();
	}
}