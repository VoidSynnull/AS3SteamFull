package game.scenes.shrink.bedroomShrunk02.PendulumSystem
{
	import flash.geom.Point;
	
	import engine.components.Spatial;
	
	import game.data.motion.time.FixedTimestep;
	import game.systems.GameSystem;
	
	public class PendulumSystem extends GameSystem
	{
		private var waitTime:Number = .25;
		private var dampening:Number = .95;
		
		public function PendulumSystem()
		{
			super(PendulumNode, updateNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		public function updateNode(node:PendulumNode, time:Number):void
		{
			var rotation:Number = node.spatial.rotation;
			var ball:Spatial = node.pendulum.renderNode.spatial;
			ball.x = node.spatial.x + Math.sin(-rotation * Math.PI / 180) * node.pendulum.radius;
			ball.y = node.spatial.y + Math.cos(-rotation * Math.PI / 180) * node.pendulum.radius;
			
			if(node.pendulum.lastCollision != null)
			{
				node.pendulum.lasHitTime += time;
				if(node.pendulum.lasHitTime >= waitTime)
					node.pendulum.lastCollision = null;
			}
			
			for(var pendulum:PendulumNode = super.nodeList.head; pendulum; pendulum = pendulum.next)
			{
				if(node == pendulum || node.pendulum.lastCollision == pendulum.pendulum.renderNode.entity)
					continue;
				
				var myBallsPoint:Point = new Point(ball.x, ball.y); 
				
				var theirBall:Spatial = pendulum.pendulum.renderNode.spatial;
				
				var theirBallsPoint:Point = new Point(theirBall.x, theirBall.y);
				
				var difference:Number = Point.distance(myBallsPoint, theirBallsPoint);
				
				if(difference < ball.width * 4 / 5)
				{
					var myVel:Number = node.motion.rotationVelocity * dampening;
					node.motion.rotationVelocity -= myVel;
					pendulum.motion.rotationVelocity += myVel;
					node.pendulum.lastCollision = pendulum.pendulum.renderNode.entity;
					pendulum.pendulum.lastCollision = node.pendulum.renderNode.entity;
					node.pendulum.lasHitTime = 0;
					pendulum.pendulum.lasHitTime = 0;
					pendulum.spatial.rotation += pendulum.motion.rotationVelocity * Math.PI / 180;
					node.pendulum.hit.dispatch();
					break;
				}
			}
		}
	}
}