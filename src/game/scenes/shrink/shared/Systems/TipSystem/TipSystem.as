package game.scenes.shrink.shared.Systems.TipSystem
{
	import engine.components.Motion;
	
	import game.systems.GameSystem;
	
	public class TipSystem extends GameSystem
	{
		public function TipSystem()
		{
			super(TipNode, updateNode);
		}
		
		public function updateNode(node:TipNode, time:Number):void
		{
			if(node.tip.state == Tip.PUSHING)
			{
				var motion:Motion = node.tip.currentHit.get(Motion);
				var angularVelocity:Number = motion.lastVelocity.x * Math.PI * time;
				if(angularVelocity > 0 && node.tip.tippingPoint > 0 || angularVelocity < 0 && node.tip.tippingPoint < 0)
				{
					node.motion.rotationAcceleration = angularVelocity;
				}
			}
			
			if(node.tip.state != Tip.BALLANCED)
			{
				var rotation:Number = 90;
				if(node.tip.tippingPoint < 0)
					rotation = -90;
				
				if(Math.abs(node.motion.rotation) > Math.abs(rotation))
				{
					node.motion.rotation = rotation;
					node.motion.rotationVelocity = node.motion.rotationAcceleration = 0;
					
					node.tip.state = Tip.BALLANCED;
					node.tip.tipped.dispatch(node.entity);
					return;
				}
				
				if(node.tip.state == Tip.TIPPING)
				{
					if(Math.abs(node.motion.rotation) < Math.abs(node.tip.tippingPoint))
					{
						var acc:Number = 180;
						if(node.motion.rotation > 0)
							acc *= -1;
						
						node.motion.rotationAcceleration = acc;
					}
					
					if(Math.abs(node.motion.rotation) < 1)
					{
						node.motion.rotationVelocity = node.motion.rotationAcceleration = node.motion.rotation = 0;
						node.tip.state = Tip.BALLANCED;
					}
				}
				else
				{
					if(node.motion.rotation < 0  && node.tip.tippingPoint > 0 || node.motion.rotation > 0 && node.tip.tippingPoint < 0)
					{
						node.motion.rotationVelocity = node.motion.rotationAcceleration = node.motion.rotation = 0;
						node.tip.state = Tip.BALLANCED;
					}
				}
			}
		}
	}
}