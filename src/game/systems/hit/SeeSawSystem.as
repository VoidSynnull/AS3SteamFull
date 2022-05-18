package game.systems.hit
{
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.components.Spatial;
	
	import game.components.hit.EntityIdList;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.motion.MassNode;
	import game.nodes.hit.SeeSawNode;
	import game.systems.GameSystem;
	
	public class SeeSawSystem extends GameSystem
	{
		public function SeeSawSystem()
		{
			super(SeeSawNode, updateNode, addedNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		private function addedNode(node:SeeSawNode):void
		{
			_massList = systemManager.getNodeList(MassNode);
		}
		
		private function updateNode(node:SeeSawNode, time:Number):void
		{
			var collisionList:EntityIdList = node.entityIdList;
			var colliding:Boolean = false;
			
			var leftTotalMass:Number = node.seeSaw.leftMass;
			var rightTotalMass:Number = node.seeSaw.rightMass;
			
			if(collisionList != null)
			{
				for(var massNode:MassNode = _massList.head; massNode; massNode = massNode.next)
				{
					if(collisionList.entities.indexOf(massNode.id.id) != -1)
					{
						colliding = true;
						var distanceX:Number = massNode.spatial.x - node.spatial.x;	
						// if we are to the left of the center
						if(distanceX < 0)
						{
							distanceX *= -1;							
							leftTotalMass += massNode.mass.mass * (distanceX / -node.edge.rectangle.left);						
						}
						else
						{
							// to the right
							rightTotalMass += massNode.mass.mass * (distanceX / node.edge.rectangle.right);
						}
					}
				}
			}			
			
			var accel:Number = rightTotalMass - leftTotalMass;
			if(colliding)
			{
				// Check where the velocity is at to see what angle we should check against
				if(node.motion.rotationVelocity < 0)
				{
					if(node.motion.rotation > node.seeSaw.leftMaxAngle)
					{
						node.motion.rotationAcceleration = accel;
						node.seeSaw.maxedLeft = node.seeSaw.maxedRight = false;
					}
					else
					{
						if(!node.seeSaw.maxedLeft)
						{
							node.seeSaw.maxTiltReached.dispatch(node.entity, false);
							node.seeSaw.maxedLeft = true;
						}
						node.motion.rotationAcceleration = 0;
						node.motion.rotationVelocity = 0;
						node.motion.rotation = node.seeSaw.leftMaxAngle;
					}
				}
				else if(node.motion.rotationVelocity > 0)
				{
					if(node.motion.rotation < node.seeSaw.rightMaxAngle)
					{
						node.motion.rotationAcceleration = accel;
						node.seeSaw.maxedLeft = node.seeSaw.maxedRight = false;
					}
					else
					{
						if(!node.seeSaw.maxedRight)
						{
							node.seeSaw.maxTiltReached.dispatch(node.entity, true);
							node.seeSaw.maxedRight = true;
						}
						node.motion.rotationAcceleration = 0;
						node.motion.rotationVelocity = 0;
						node.motion.rotation = node.seeSaw.rightMaxAngle;
					}
				}
				else if(node.motion.rotationVelocity == 0)
				{
					if((accel < 0 && node.motion.rotation > node.seeSaw.leftMaxAngle) || (accel > 0 && node.motion.rotation < node.seeSaw.rightMaxAngle))
					{
						node.motion.rotationAcceleration = accel;
						node.seeSaw.maxedLeft = node.seeSaw.maxedRight = false;
					}
				}
			}
			else
			{
				if(node.motion.rotation + accel *time > node.seeSaw.leftMaxAngle && node.motion.rotation + accel * time < node.seeSaw.rightMaxAngle)
				{
					node.motion.rotationAcceleration = accel;
					node.seeSaw.maxedLeft = node.seeSaw.maxedRight = false;
				}
				else if(node.motion.rotation < node.seeSaw.leftMaxAngle)
				{
					if(!node.seeSaw.maxedLeft)
					{
						node.seeSaw.maxTiltReached.dispatch(node.entity, false);
						node.seeSaw.maxedLeft = true;
					}
					node.motion.rotationAcceleration = 0;
					node.motion.rotationVelocity = 0;
					node.motion.rotation = node.seeSaw.leftMaxAngle;
				}
				else if(node.motion.rotation > node.seeSaw.rightMaxAngle)
				{
					if(!node.seeSaw.maxedRight)
					{
						node.seeSaw.maxTiltReached.dispatch(node.entity, true);
						node.seeSaw.maxedRight = true;
					}
					node.motion.rotationAcceleration = 0;
					node.motion.rotationVelocity = 0;
					node.motion.rotation = node.seeSaw.rightMaxAngle;
				}
			}
			
			
			if(node.seeSaw.tiltingRight != node.motion.rotationVelocity > 0 && node.motion.rotationVelocity != 0)
			{
				node.seeSaw.tiltingRight = node.motion.rotationVelocity > 0;
				node.seeSaw.changedDirections.dispatch(node.entity, node.seeSaw.tiltingRight);
			}
			
			// Check if we need to sync a display's rotation
			if(node.seeSaw.follow != null)
			{
				var displaySpatial:Spatial = node.seeSaw.follow.get(Spatial);
				displaySpatial.rotation = node.spatial.rotation;	
			}					
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(MassNode);
			_massList = null;
		}
		
		private var _massList:NodeList;
	}
}