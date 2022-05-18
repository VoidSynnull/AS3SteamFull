/**
 * Handles hits inside a zone.  Dispatches signals on the hit entity but doesn't directly modify the entity in the zone.
 * 
 * example:
 *  1.  Add a movieclip in hits.fla with the word 'zone' in it for the hit entity to be automatically added by HitCreator.
 * 
 *  2.  Add the following code to the scene after it has loaded to access the hit entity: 
 * 
 *  // get a hit entity with instance name / id 'zoneShrink'
 *  var zoneHitEntity:Entity = super.getEntityById("zoneShrink");
 * 
 *  // get the hit component.
 *	var zoneHit:Zone = zoneHitEntity.get(Zone);
 *	// optionally add handlers for all the zone events.
 *	zoneHit.entered.add(handleZoneEntered);
 *	zoneHit.exitted.add(handleZoneExitted);
 *	zoneHit.inside.add(handleZoneInside);
 *	 
 *	// if a precise hit test is needed, set the point and shape flags as necessary.
 *	zoneHit.shapeHit = false;
 *	zoneHit.pointHit = true;
 * 
 * */

package game.systems.hit
{
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.ShellApi;
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.hit.Zone;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.collider.ZoneCollisionNode;
	import game.nodes.hit.ZoneHitNode;
	import game.systems.GameSystem;
	import game.util.EntityUtils;
	
	public class ZoneHitSystem extends GameSystem
	{
		public function ZoneHitSystem()
		{
			super(ZoneCollisionNode, updateNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			_hits = systemManager.getNodeList(ZoneHitNode);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(ZoneCollisionNode);
			systemManager.releaseNodeList(ZoneHitNode);
			_hits = null;
			
			super.removeFromEngine(systemManager);
		}
		
		private function updateNode(node:ZoneCollisionNode, time:Number):void
		{
			var spatial:Spatial = node.spatial;
			var hitDisplay:Display;
			var hitNode:ZoneHitNode;
			var isHit:Boolean;
			
			for (hitNode = _hits.head; hitNode; hitNode = hitNode.next )
			{
				if (EntityUtils.sleeping(hitNode.entity))
				{
					continue;
				}
				
				hitDisplay = hitNode.display;
				
				isHit = false;
				
				if(hitNode.zone.pointHit)
				{
					if (hitDisplay.displayObject.hitTestPoint(_shellApi.offsetX(node.spatial.x), _shellApi.offsetY(node.spatial.y), hitNode.zone.shapeHit))
					{
						enter(hitNode, node);
						isHit = true;
					}
				}
				else
				{
					if (hitDisplay.displayObject.hitTestObject(node.display.displayObject))
					{
						enter(hitNode, node);
						isHit = true;
					}
				}
				
				if(!isHit)
				{
					exit(hitNode, node);
				}
			}
		}
		
		private function exit(hitNode:ZoneHitNode, colliderNode:ZoneCollisionNode):void
		{
			if(colliderNode.collider.zones != null)
			{
				var zone:Zone = colliderNode.collider.zones[hitNode.id.id];
				
				if(zone != null)
				{
					zone.exitted.dispatch(hitNode.id.id, colliderNode.id.id);
					colliderNode.collider.zones[hitNode.id.id] = null;
				}
			}
		}
		
		private function enter(hitNode:ZoneHitNode, colliderNode:ZoneCollisionNode):void
		{
			if(colliderNode.collider.zones != null)
			{
				var zone:Zone = colliderNode.collider.zones[hitNode.id.id];
				
				if(zone == null)
				{
					zone = hitNode.zone;
					zone.entered.dispatch(hitNode.id.id, colliderNode.id.id);
					colliderNode.collider.zones[hitNode.id.id] = zone;
				}
				
				zone.inside.dispatch(hitNode.id.id, colliderNode.id.id);
			}
		}
		
		private var _hits:NodeList;
		[Inject]
		public var _shellApi:ShellApi;
	}
}