package game.scenes.cavern1.shared.systems
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Motion;
	
	import game.components.hit.Platform;
	import game.components.hit.Wall;
	import game.scenes.cavern1.shared.nodes.BreakableNode;
	import game.systems.GameSystem;
	import game.util.MotionUtils;
	
	public class BreakableSystem extends GameSystem
	{
		public function BreakableSystem()
		{
			super(BreakableNode, updateNode);
		}
		
		private function updateNode(node:BreakableNode, time:Number):void
		{
			if(!node.hit.isHit)
			{
				node.breakable.delay += time;
				if(node.breakable.delay > node.breakable.fallDelay)
				{
					node.motion.acceleration.y = MotionUtils.GRAVITY;
					node.breakable.falling = true;
				}
			}
			else
			{
				if(node.breakable.delay < node.breakable.fallDelay)
				{
					node.breakable.delay = 0;
					node.breakable.falling = false;
				}
				if(node.breakable.falling)
				{
					node.breakable.falling = false;
					if(node.breakable.delay < node.breakable.fallDelay)
					{
						node.breakable.delay = 0;
						return;
					}
					
					node.entity.remove(Wall);
					node.breakable.platform.remove(Platform);
					//explode
					for each (var child:Entity in node.children.children)
					{
						var angle:Number = Math.random() * 360;
						var velX:Number = Math.cos(angle) * node.breakable.explosiveness;
						var velY:Number = Math.sin(angle) * node.breakable.explosiveness;
						var motion:Motion = child.get(Motion);
						motion.rotationVelocity = (-1 + Math.random() * 2) * 3.6 * node.breakable.explosiveness;
						motion.velocity = new Point(velX, velY);
						motion.acceleration.y = MotionUtils.GRAVITY;
					}
				}
			}
		}
	}
}