package game.scenes.shrink.shared.Systems.CarSystem
{
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.systems.GameSystem;
	import game.util.TweenUtils;
	
	public class CarSystem extends GameSystem
	{
		public function CarSystem()
		{
			super(CarNode, updateNode);
		}
		
		public function updateNode(node:CarNode, time:Number):void
		{
			for(var i:int = 0; i < node.car.wheels.length; i++)
			{
				var wheel:Motion = node.car.wheels[i];
				wheel.rotationVelocity = node.motion.velocity.x / (Math.PI * node.car.wheelRadius) * 180;
			}
			
			var rotation:Number = -node.motion.velocity.x * node.car.leanScale;
			
			if(rotation > node.car.maxLean)
				rotation = node.car.maxLean;
			if(rotation < -node.car.maxLean)
				rotation = -node.car.maxLean;
			
			if(node.motion.velocity.x > node.car.maxSpeed)
				node.motion.velocity.x = node.car.maxSpeed;
			if(node.motion.velocity.x < -node.car.maxSpeed)
				node.motion.velocity.x = -node.car.maxSpeed;
			
			TweenUtils.entityTo(node.car.body, Spatial, 1,{rotation:rotation});
		}
	}
}