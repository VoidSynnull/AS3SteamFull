package game.scenes.backlot.sunriseStreet.Systems
{
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.hit.Platform;
	import game.nodes.entity.collider.PlatformCollisionNode;
	import game.scenes.backlot.sunriseStreet.components.SpringBoard;
	import game.scenes.backlot.sunriseStreet.nodes.SpringNode;
	import game.systems.GameSystem;
	
	public class SpringBoardSystem extends GameSystem
	{
		override public function SpringBoardSystem():void
		{
			super(SpringNode, updateNode);
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			_colliders = systemManager.getNodeList(PlatformCollisionNode);
		}
		
		private function updateNode(springNode:SpringNode, time:Number):void
		{
			// spring board attributes
			var platformColliders:uint = springNode.entity.get(Platform).colliders;
			var motion:Motion = springNode.motion;
			var spatial:Spatial = springNode.spatial;
			var spring:SpringBoard = springNode.spring;
			
			// charAttributes
			var node:PlatformCollisionNode;
			var charSpatial:Spatial;
			
			// calculating variables
			var distance:Number;
			var deltaR:Number = spring.restingRotation - spatial.rotation;
			
			if( platformColliders > 0 )
			{
				for( node = _colliders.head; node; node = node.next )
				{
					charSpatial = node.entity.get( Spatial );
					
					distance = Point.distance(new Point(charSpatial.x, charSpatial.y), new Point(spatial.x, spatial.y));
					
					// if to the left					
					if(charSpatial.x < spatial.x)
					{
						//give way to the left
						motion.rotationAcceleration = -distance - 250 + deltaR * spring.springVelocity;
						
						// until the point elasticity springs back
						if(motion.rotationVelocity > 0)
						{
							// launch player up based on how far from the pivot the are and the springyness of the board
							node.motion.acceleration.y = -distance * spring.springVelocity * 10;
							spring.spring.dispatch();
						}
					}
					else
					{
						//give way to the right                 note: deltaR goes both positive and negative which is why it is also added
						motion.rotationAcceleration = distance + 250 + deltaR * spring.springVelocity;
						// until the point elasticity springs back
						if(motion.rotationVelocity < 0)
						{
							// launch player up based on how far from the pivot the are and the springyness of the board
							node.motion.acceleration.y = -distance * spring.springVelocity * 10;
							spring.spring.dispatch();
						}
					}
				}
			}
			else
			{
				// when nothing is on the spring board continue springing motion
				motion.rotationAcceleration = deltaR * spring.springVelocity;
				// but dampen it so it doesnt continue on forever / get out of control
				
				var dampening:Number = 1 - spring.dampening; // making numbers make sense with there effect
				
				if(dampening >1)
					dampening = 1;
				if(dampening < 0)
					dampening = 0;
				
				// and not let crazy numbers break it
				
				motion.rotationVelocity *= dampening;

				//when it has slowed down enough just stop it so it doesnt launch player with the slightest movement
				if(Math.abs(deltaR) < 1 && Math.abs(motion.rotationVelocity) < 1)
				{
					spatial.rotation = spring.restingRotation;
					motion.rotationAcceleration = 0;
					motion.rotationVelocity = 0;
				}
			}
		}
		
		private var _colliders:NodeList;
	}
}