package game.scenes.shrink.bedroomShrunk02.SeaMonkeySystem
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import game.systems.GameSystem;
	
	public class SeaMonkeySystem extends GameSystem
	{
		public function SeaMonkeySystem()
		{
			super(SeaMonkeyNode, updateNode);
		}
		
		public function updateNode(node:SeaMonkeyNode, time:Number):void
		{
			node.monkey.moveTime -= time;
			if(node.monkey.moveTime <= 0)
				setNewDirection(node);
			
			if(node.spatial.x > node.monkey.tank.right && node.motion.velocity.x > 0 || node.spatial.x < node.monkey.tank.left && node.motion.velocity.x < 0 )
				node.motion.velocity.x *= -1;
			
			if(node.spatial.y > node.monkey.tank.bottom && node.motion.velocity.y > 0  || node.spatial.y < node.monkey.tank.top && node.motion.velocity.y < 0 )
				node.motion.velocity.y *= -1;
			
			if(node.motion.velocity.x > 0)
				node.spatial.scaleX = -1;
			else
				node.spatial.scaleX = 1;
			
			if(node.monkey.target == null)
				node.monkey.moveToTarget = false;
			else
			{
				var target:Point = new Point(node.monkey.target.x, node.monkey.target.y);
				var targetZone:Rectangle = new Rectangle(node.monkey.tank.left - node.monkey.tank.width, node.monkey.tank.top, node.monkey.tank.width * 3, node.monkey.tank.height * 2);
				if(targetZone.containsPoint(target))
					node.monkey.moveToTarget = true;
				else
					node.monkey.moveToTarget = false;
			}
		}
		
		private function setNewDirection(node:SeaMonkeyNode):void
		{
			var times:Point = node.monkey.directionTime;
			var diff:Number = times.y - times.x;
			node.monkey.moveTime = times.x + Math.random() * diff;
			var direction:Number;
			if(node.monkey.moveToTarget)
			{
				var monkeyPos:Point = new Point(node.spatial.x, node.spatial.y);
				var targetPos:Point = new Point(node.monkey.target.x, node.monkey.target.y);
				var difference:Point = new Point(targetPos.x - monkeyPos.x, targetPos.y - monkeyPos.y);
				direction = Math.atan2(difference.y, difference.x);
				var velY:Number = Math.random() * node.monkey.speed * 2 - node.monkey.speed;
				node.motion.velocity = new Point(Math.cos(direction)* node.monkey.speed, velY);
			}
			else
			{
				direction = Math.random() * Math.PI * 2;
				node.motion.velocity = new Point(Math.cos(direction) * Math.random() * node.monkey.speed, Math.sin(direction) * Math.random() * node.monkey.speed);
			}
		}
	}
}