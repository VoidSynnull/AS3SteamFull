package game.systems.hit
{
	import flash.display.BitmapData;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.ShellApi;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.collider.BitmapCollider;
	import game.components.hit.EntityIdList;
	import game.components.motion.Edge;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.collider.WallCollisionNode;
	import game.nodes.hit.BitmapHitAreaNode;
	import game.nodes.hit.WallBitmapHitNode;
	import game.nodes.hit.WallHitNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;

	public class WallHitSystem extends GameSystem
	{
		public function WallHitSystem()
		{
			super(WallCollisionNode, updateNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			super._defaultPriority = SystemPriorities.resolveCollisions;
		}

		override public function addToEngine(systemManager:Engine):void
		{
			_hits = systemManager.getNodeList(WallHitNode);
			_bitmapHits = systemManager.getNodeList(WallBitmapHitNode);
			_hitAreaNodes = systemManager.getNodeList(BitmapHitAreaNode);
			_hitAreaNode = _hitAreaNodes.head;
			
			super.addToEngine(systemManager);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(WallCollisionNode);
			systemManager.releaseNodeList(WallHitNode);
			systemManager.releaseNodeList(WallBitmapHitNode);
			systemManager.releaseNodeList(BitmapHitAreaNode);
			
			_hitAreaNode = null;
			_hitAreaNodes = null;
			_hits = null;
			_bitmapHits = null;
			
			super.removeFromEngine(systemManager);
		}
		
		override public function update(time:Number):void
		{			
			if(_hitAreaNode == null)
			{
				_hitAreaNode = _hitAreaNodes.head;
			}
			else
			{
				super.update(time);
			}
		}
		
		private function updateNode(node:WallCollisionNode, time:Number):void
		{
			var motion:Motion = node.motion;
			var hitDisplay:Display;
			var bitmapCollider:BitmapCollider = node.bitmapCollider;
			var hitNode:WallHitNode;
			var bitmapHitNode:WallBitmapHitNode;
			
			node.collider.isHit = false;
			
			if(bitmapCollider.centerColor != 0 || bitmapCollider.color != 0)
			{
				for (bitmapHitNode = _bitmapHits.head; bitmapHitNode; bitmapHitNode = bitmapHitNode.next )
				{
					if(bitmapCollider.color == bitmapHitNode.bitmapHit.color)
					{
						node.collider.isHit = true;
						if(node.currentHit != null){
							node.currentHit.hit = bitmapHitNode.entity;
						}
						bitmapHit(node);
						setMotion(node);
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
				
				if(node.validHit != null)
				{
					if(hitNode.id != null)
					{
						//if(node.validHit.hitIds[hitNode.id.id] == node.validHit.inverse)
						if(!node.validHit.hitIds[hitNode.id.id] && !node.validHit.inverse
						|| node.validHit.hitIds[hitNode.id.id] && node.validHit.inverse)
						{
							continue;
						}
					}
				}
				
				hitDisplay = hitNode.display;
				
				if (hitDisplay.displayObject.hitTestPoint(_shellApi.offsetX(node.motion.x), _shellApi.offsetY(node.motion.y), true))
				{
					if(node.currentHit != null){
						node.currentHit.hit = hitNode.entity;
					}
					hit(hitDisplay.displayObject.x, hitDisplay.displayObject.width, motion, node.edge);
					setMotion(node);
					updateHitList(node, hitNode);
					return;
				}
			}
		}

		private function setMotion(node:WallCollisionNode):void
		{
			node.collider.isHit = true;
			
			if(node.motion.acceleration.x > 0)
			{
				node.collider.direction = 1;
			}
			else if(node.motion.acceleration.x < 0)
			{
				node.collider.direction = -1;
			}
			
			node.motion.zeroMotion("x");
		}
				
		private function bitmapHit(wallCollisionNode:WallCollisionNode):void
		{						
			var index:Number = 0;
			var motion:Motion = wallCollisionNode.motion;
			var collider:BitmapCollider = wallCollisionNode.bitmapCollider;
			var edge:Edge = wallCollisionNode.edge;
			var hitArea:BitmapData = _hitAreaNode.bitmapHitArea.bitmapData;
			var hitAreaSpatial:Spatial = _hitAreaNode.spatial;
			
			while(motion.velocity.x != 0)
			{
				if(Math.abs(index) < 20 && hitArea.getPixel((collider.hitX + index) * hitAreaSpatial.scale + hitAreaSpatial.x, motion.y * hitAreaSpatial.scale + hitAreaSpatial.y) == collider.color)
				{
					if(motion.velocity.x < 0)
					{
						index++;
					}
					else
					{
						index--;
					}
				}
				else
				{
					if(edge)
					{
						if(index > 0)
						{
							motion.x = collider.hitX + index + edge.rectangle.right;
						}
						else
						{
							motion.x = collider.hitX + index + edge.rectangle.left;
						}
					}
					else
					{
						motion.x = collider.hitX + index;
					}
					return;
				}
			}
		}
		
		private function updateHitList(collisionNode:WallCollisionNode, hitNode:*):void
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
		
		private function hit(x:Number, distance:Number, motion:Motion, edge:Edge = null):void
		{						
			var offsetX:Number = 0;

			if (motion.x >= x && motion.velocity.x <= 0) 
			{
				if(edge != null)
				{
					offsetX = edge.rectangle.right;
				}
				
				setHit(x, distance, motion, 1, offsetX);
			}
			else if (motion.x <= x && motion.velocity.x >= 0) 
			{
				if(edge != null)
				{
					offsetX = -edge.rectangle.right;
				}
				
				setHit(x, distance, motion, -1, offsetX);
			}
		}
		
		private function setHit(x:Number, distance:Number, motion:Motion, dir:Number, offsetX:Number = 0):void
		{
			motion.x = x + offsetX + (distance * .5 - 1) * dir;
		}
		
		private function switchedDirection(node:WallCollisionNode):Boolean
		{
			return(node.motion.acceleration.x > 0 && node.collider.direction < 0 ||
				   node.motion.acceleration.x < 0 && node.collider.direction > 0);
		}
		
		private var _bitmapHits:NodeList;
		private var _hits:NodeList;
		private var _hitAreaNode:BitmapHitAreaNode;
		private var _hitAreaNodes:NodeList;
	
		[Inject]
		public var _shellApi:ShellApi;
	}
}
