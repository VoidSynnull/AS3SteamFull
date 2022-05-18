package game.systems.hit
{
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import game.components.entity.collider.SceneObjectCollider;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.collider.GravityWellCollisionNode;
	import game.nodes.hit.GravityWellNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.GeomUtils;
	
	public class GravityWellSystem extends GameSystem
	{
		public function GravityWellSystem()
		{
			super(GravityWellCollisionNode, updateNode);
			
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			
			super._defaultPriority = SystemPriorities.move;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			_hits = systemManager.getNodeList(GravityWellNode);
		}
		
		private function updateNode(collision:GravityWellCollisionNode, time:Number):void
		{			
			for(var hitNode:GravityWellNode = _hits.head; hitNode; hitNode = hitNode.next)
			{
				// Get Distance of hit from well
				var dist:Number = GeomUtils.dist(collision.spatial.x, collision.spatial.y, hitNode.spatial.x, hitNode.spatial.y);
				
				if(dist <= hitNode.gravityWellHit.hitRange){
					hitNode.gravityWellHit.hitSignal.dispatch();
				}

				if(Math.abs(dist) < hitNode.gravityWellHit.radius && Math.abs(dist) > hitNode.gravityWellHit.hitRange)
				{
					collision.gravityWellCollider.inRange = true;
					var force:Number = GRAVITY_CONST * (hitNode.gravityWellHit.mass/(dist*dist));					
					var angle:Number = GeomUtils.radiansBetween(collision.spatial.x, collision.spatial.y, hitNode.spatial.x, hitNode.spatial.y);
					
					// see if we should reverse the direction we push the player
					var direction:Number = hitNode.gravityWellHit.reversed ? -1 : 1;
					
					if(!collision.motion.parentVelocity)
						collision.motion.parentVelocity = new Point();
					
					collision.motion.parentVelocity.x = Math.cos(angle) * force * direction;
					collision.motion.parentVelocity.y = Math.sin(angle) * force * direction;
					
					if(collision.entity.get(SceneObjectCollider) != null){
						collision.entity.remove(SceneObjectCollider); // remove scene object collider (for multiple objects getting pulled in)
					}
				}
				else if(collision.gravityWellCollider.inRange)
				{
					collision.motion.zeroAcceleration();
					collision.gravityWellCollider.inRange = false;
				}
			}
		}
		
		private var _hits:NodeList;
		private const GRAVITY_CONST:Number = 4000;
	}
}