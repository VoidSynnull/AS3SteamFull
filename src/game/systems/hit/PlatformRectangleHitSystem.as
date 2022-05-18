package game.systems.hit
{
	import game.nodes.entity.collider.PlatformCollisionNode;
	import game.nodes.hit.PlatformHitNode;
	import game.nodes.hit.PlatformRectangleHitNode;
	import game.systems.GameSystem;
	import game.util.MotionUtils;
	
	public class PlatformRectangleHitSystem extends GameSystem
	{
		public function PlatformRectangleHitSystem()
		{
			super(PlatformCollisionNode, updateNode);
		}
		
		private function updateNode(collisionNode:PlatformCollisionNode, time:Number):void
		{
			
		}
		
		private function getYBaseFromRect(hitNode:PlatformHitNode, collisionNode:PlatformCollisionNode):Number
		{
			var hitPosition:* = MotionUtils.getPositionComponent(hitNode);
			var platformAngle:Number = Math.tan(hitPosition.rotation * Math.PI / 180);
			var xDelta:Number = collisionNode.motion.x - hitPosition.x;
			if(hitNode.hit.top)
			{
				return (hitPosition.y + hitNode.hit.hitRect.top * .9) + (xDelta * platformAngle);
			}
			else
			{
				return (hitPosition.y + hitNode.hit.hitRect.top + hitNode.hit.hitRect.height/2) + (xDelta * platformAngle);
			}
		}
	}
}