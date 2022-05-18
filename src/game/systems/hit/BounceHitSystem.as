package game.systems.hit
{
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Motion;
	
	import game.components.entity.collider.BitmapCollider;
	import game.components.hit.Bounce;
	import game.components.timeline.Timeline;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.collider.SceneCollisionNode;
	import game.nodes.hit.BounceBitmapHitNode;
	import game.nodes.hit.BounceHitNode;
	import game.systems.GameSystem;
	import game.util.EntityUtils;

	public class BounceHitSystem extends GameSystem
	{
		public function BounceHitSystem()
		{
			super(SceneCollisionNode, updateNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}

		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			_hits = systemManager.getNodeList(BounceHitNode);
			_bitmapHits = systemManager.getNodeList(BounceBitmapHitNode);
		}
				
		private function updateNode(node:SceneCollisionNode, time:Number):void
		{
			var bitmapHitNode:BounceBitmapHitNode;
			var hitNode:BounceHitNode;
			var motion:Motion;
			var hitDisplay:Display;
			var bitmapCollider:BitmapCollider = node.bitmapCollider;

			motion = node.motion;
			
			if (motion.velocity.y > MINIMUM_BOUNCE_VELOCITY)
			{
				if(bitmapCollider.platformColor != 0)
				{
					for (bitmapHitNode = _bitmapHits.head; bitmapHitNode; bitmapHitNode = bitmapHitNode.next )
					{
						if(node.validHit != null)
						{
							if(bitmapHitNode.id != null)
							{
								//if(collisionNode.validHit.hitIds[hitNode.id.id] == collisionNode.validHit.inverse)
								if(!node.validHit.hitIds[bitmapHitNode.id.id] && !node.validHit.inverse
									|| node.validHit.hitIds[bitmapHitNode.id.id] && node.validHit.inverse)
								{
									continue;
								}
							}
						}
						if(bitmapCollider.platformColor == bitmapHitNode.bitmapHit.color)
						{
							setHit(node, bitmapHitNode);
							return;
						}
					}
				}
				
				for ( hitNode = _hits.head; hitNode; hitNode = hitNode.next )
				{
					if (EntityUtils.sleeping(hitNode.entity))
					{
						continue;
					}
					
					hitDisplay = hitNode.display;
					
					if (motion.velocity.y > 0)
					{
						if(node.validHit != null)
						{
							if(hitNode.id != null)
							{
								//if(collisionNode.validHit.hitIds[hitNode.id.id] == collisionNode.validHit.inverse)
								if(!node.validHit.hitIds[hitNode.id.id] && !node.validHit.inverse
									|| node.validHit.hitIds[hitNode.id.id] && node.validHit.inverse)
								{
									continue;
								}
							}
						}
						if (hitDisplay.displayObject.hitTestObject(node.display.displayObject))
						{
							setHit(node, hitNode);
							break;
						}
					}
				}
			}
		}

		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(SceneCollisionNode);
			systemManager.releaseNodeList(BounceHitNode);
			systemManager.releaseNodeList(BounceBitmapHitNode);
			_hits = null;
			_bitmapHits = null;
			super.removeFromEngine(systemManager);
		}
		
		private function setHit(collisionNode:SceneCollisionNode, hitNode:*):void
		{
			var hit:Bounce = hitNode.hit;
			
			collisionNode.motion.velocity.x += hit.velocity.x;
			collisionNode.motion.velocity.y = hit.velocity.y;
			collisionNode.currentHit.hit = hitNode.entity;
			
			EntityUtils.playAudioAction(collisionNode.hitAudio, hitNode.hitAudioData);
			
			if ((hit.animate) && (hit.timeline))
				hit.timeline.get(Timeline).gotoAndPlay(2);
		}
		
		private var _bitmapHits:NodeList;
		private var _hits:NodeList;
		private const MINIMUM_BOUNCE_VELOCITY:uint = 100;
	}
}
