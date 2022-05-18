package game.scenes.time.china.systems
{	
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.nodes.entity.collider.PlatformCollisionNode;
	import game.scenes.time.china.nodes.RotatingPlatformNode;
	import game.systems.GameSystem;
	
	import org.osflash.signals.Signal;
	
	public class RotatingPlatformSystem extends GameSystem
	{
		
		public function RotatingPlatformSystem()
		{
			super(RotatingPlatformNode, updateNode);
		}
		
		override public function addToEngine( systemManager:Engine ):void
		{
			super.addToEngine(systemManager);
			_colliders = systemManager.getNodeList(PlatformCollisionNode);
			_collisionNode = _colliders.head;
		}
		
		private function updateNode(collisionNode:RotatingPlatformNode, time:Number):void
		{
			var platformColliders:uint = collisionNode.entityIdList.entities.length;
			var motion:Motion = collisionNode.motion;
			var platformSpatial:Spatial = collisionNode.spatial;
			
			var displaySpatial:Spatial = collisionNode.rotatingPlatform.spatial;
			var displayEntMotion:Motion = collisionNode.rotatingPlatform.motion;
			
			var charSpatial:Spatial;
			var deltaX:Number;
			var deltaR:Number;
			var hitX:Number;
			
			if( platformColliders > 0 )
			{
				charSpatial = _collisionNode.spatial;
				deltaX = charSpatial.x - collisionNode.rotatingPlatform.pivotPoint.x;
				
				// if standing negligibly close to the pivot
				if ( Math.ceil( Math.abs( deltaX )) < 10 )
				{
					motion.rotationVelocity = displayEntMotion.rotationVelocity = 0;
					motion.rotationAcceleration = displayEntMotion.rotationAcceleration = 0;
				}
				//	if standing on the right of pivot
				else if( deltaX > platformSpatial.rotation )
				{
					if( platformSpatial.rotation > Math.floor( deltaX / 20 ))
					{
						platformSpatial.rotation = displaySpatial.rotation = deltaX / 20;
						motion.rotationVelocity = displayEntMotion.rotationVelocity = 0;
						motion.rotationAcceleration = displayEntMotion.rotationAcceleration = 0;
					}
					else
					{
						_armMoved.dispatch( collisionNode.id.id );
						motion.rotationAcceleration = displayEntMotion.rotationAcceleration = deltaX / 10;
					}
				}
				// if standing on the left of pivot
				else
				{
					if( platformSpatial.rotation < Math.ceil( deltaX / 20 ))
					{
						platformSpatial.rotation = displaySpatial.rotation = deltaX / 20;
						motion.rotationVelocity = displayEntMotion.rotationVelocity = 0;
						motion.rotationAcceleration = displayEntMotion.rotationAcceleration = 0;
					}
					else
					{
						_armMoved.dispatch( collisionNode.id.id );
						motion.rotationAcceleration = displayEntMotion.rotationAcceleration = deltaX / 10;
					}
				}
			}
			else
			{
				if( platformSpatial.rotation != 0 )
				{
					if( Math.abs(platformSpatial.rotation) < 10 )
					{
						platformSpatial.rotation = displaySpatial.rotation = 0;
						motion.rotationVelocity = displayEntMotion.rotationVelocity = 0;
						motion.rotationAcceleration = displayEntMotion.rotationAcceleration = 0;
					}
					else
					{
						deltaR = platformSpatial.rotation / 10;
						
						motion.rotationVelocity -= deltaR;
						displayEntMotion.rotationVelocity -= deltaR;
					}
				}
			}
		}
		
		public var _armMoved:Signal = new Signal( String );
		private var _colliders:NodeList;
		private var _collisionNode:PlatformCollisionNode;
	}
}