package game.systems.hit
{
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.ShellApi;
	import engine.components.Display;
	import engine.components.Motion;
	
	import game.components.entity.collider.BitmapCollider;
	import game.components.hit.EntityIdList;
	import game.components.hit.Mover;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.collider.SceneCollisionNode;
	import game.nodes.hit.MoverBitmapHitNode;
	import game.nodes.hit.MoverHitNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;

	public class MoverHitSystem extends GameSystem
	{
		public function MoverHitSystem()
		{
			super(SceneCollisionNode, updateNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			super._defaultPriority = SystemPriorities.resolveParentCollisions;
		}

		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			_hits = systemManager.getNodeList(MoverHitNode);
			_bitmapHits = systemManager.getNodeList(MoverBitmapHitNode);
		}
		
		private function updateNode(node:SceneCollisionNode, time:Number):void
		{
			var motion:Motion;
			var hitDisplay:Display;
			var hitNode:MoverHitNode

			motion = node.motion;
			
			var bitmapCollider:BitmapCollider = node.bitmapCollider;
			
			if(bitmapCollider.centerColor != 0 || bitmapCollider.platformColor != 0)
			{
				for (var bitmapHitNode:MoverBitmapHitNode = _bitmapHits.head; bitmapHitNode; bitmapHitNode = bitmapHitNode.next )
				{
					if(bitmapCollider.centerColor == bitmapHitNode.bitmapHit.color || bitmapCollider.platformColor == bitmapHitNode.bitmapHit.color)
					{
						applyMotion(bitmapHitNode.hit, motion);
						updateHitList(node, bitmapHitNode);
						return;
					}
				}
			}
			
			for (hitNode = _hits.head; hitNode; hitNode = hitNode.next )
			{
				if (EntityUtils.sleeping(hitNode.entity))
				{
					continue;
				}
				
				hitDisplay = hitNode.display;
				
				if (hitDisplay.displayObject.hitTestPoint(_shellApi.offsetX(node.motion.x), _shellApi.offsetY(node.motion.y), true))
				{
					applyMotion(hitNode.hit, motion);
					updateHitList(node, hitNode);
					return;
				}
			}
		}

		private function applyMotion(hit:Mover, motion:Motion):void
		{
			if(hit.velocity != null)
			{
				if(hit.overrideVelocity)
				{
					motion.velocity.x = hit.velocity.x;
					motion.velocity.y = hit.velocity.y;
				}
				else
				{
					motion.parentVelocity = hit.velocity;
				}
			}
			
			if(hit.acceleration != null)
			{
				motion.parentAcceleration = hit.acceleration;
			}						
			
			if(!isNaN(hit.rotationVelocity))
			{
				motion.parentRotationVelocity = hit.rotationVelocity;
			}	
			
			if(hit.friction != null)
			{
				motion.parentFriction = hit.friction;
			}
		}
		
		private function updateHitList(collisionNode:SceneCollisionNode, hitNode:*):void
		{
			var hits:EntityIdList = hitNode.hits;
			
			if(hits != null)
			{
				var id:String;
				
				if(collisionNode.id)
				{
					id = collisionNode.id.id;
				}
				else
				{
					id = collisionNode.entity.name;
				}
				
				if(hits.entities.indexOf(id) < 0)
				{
					hits.entities.push(id);
				}
			}
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(SceneCollisionNode);
			systemManager.releaseNodeList(MoverHitNode);
			systemManager.releaseNodeList(MoverBitmapHitNode);
			_hits = null;
			_bitmapHits = null;
			super.removeFromEngine(systemManager);
		}
		
		[Inject]
		public var _shellApi:ShellApi;
		private var _hits:NodeList;
		private var _bitmapHits:NodeList;
	}
}
