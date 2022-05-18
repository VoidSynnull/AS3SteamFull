package game.systems.motion
{
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import game.components.hit.EntityIdList;
	import game.components.motion.Mass;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.motion.MassNode;
	import game.nodes.motion.PulleyObjectNode;
	import game.nodes.motion.PulleyRopeNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class PulleySystem extends GameSystem
	{
		public function PulleySystem()
		{
			super(PulleyObjectNode, updateNode, addedNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			
			this._defaultPriority = SystemPriorities.animate;
		}
		
		private function addedNode(node:PulleyObjectNode):void
		{
			_massList = systemManager.getNodeList(MassNode);
			_ropeList = systemManager.getNodeList(PulleyRopeNode);
			
			for(var ropeNode:PulleyRopeNode = this._ropeList.head; ropeNode; ropeNode = ropeNode.next)
			{
				ropeNode.spatial.scaleX = ropeNode.spatial.scaleY = 1;
				ropeNode.pulleyRope.originalHeight = ropeNode.spatial.height;
			}
		}
		
		private function updateNode(node:PulleyObjectNode, time:Number):void
		{
			var collisionList:EntityIdList = node.entityIdList;
			
			if(collisionList != null)
			{
				for(var massNode:MassNode = this._massList.head; massNode; massNode = massNode.next)
				{
					var id:String = massNode.id.id;
					// if the collision list has this pulleyMass object
					if(collisionList.entities.indexOf(id) != -1)
					{
						// make sure that we haven't already added it
						if(node.pulleyObject.currentCollisions.indexOf(id) == -1)
						{
							node.mass.mass += massNode.mass.mass;
							node.pulleyObject.currentCollisions.push(id);
						}
					}
					else if(node.pulleyObject.currentCollisions.indexOf(id) != -1)
					{
						node.mass.mass -= massNode.mass.mass;
						node.pulleyObject.currentCollisions.splice(node.pulleyObject.currentCollisions.indexOf(id), 1);
					}
				}	
			}
			
			var oppositeMass:Number = node.pulleyObject.opposite.get(Mass).mass;
			if(node.mass.mass > oppositeMass)
			{
				if(node.pulleyObject.maxY > node.spatial.y)
				{
					node.motion.velocity.y = node.mass.mass - oppositeMass;
					node.pulleyConnector.currentSpeed = node.motion.velocity.y;
				}
				else
				{
					node.spatial.y = node.pulleyObject.maxY;
					node.pulleyConnector.currentSpeed = 0;
					node.motion.velocity.y = 0;
				}
			}
			else if(node.mass.mass == oppositeMass)
			{
				node.pulleyConnector.currentSpeed = 0;
				node.motion.velocity.y = 0;				
			}
			else
			{
				node.motion.velocity.y = -node.pulleyConnector.currentSpeed;
			}
			
			if(node.motion.velocity.y != 0 && !node.pulleyObject.moving)
			{
				node.pulleyObject.moving = true;
				node.pulleyObject.startMoving.dispatch(node.entity);
			}
			else if(node.motion.velocity.y == 0 && node.pulleyObject.moving)
			{
				node.pulleyObject.moving = false;
				node.pulleyObject.stopMoving.dispatch(node.entity);
			}
			
			// if there is a wheel rotate it
			if(node.pulleyObject.wheel != null)
			{
				node.pulleyObject.wheel.rotation += node.motion.velocity.y * node.pulleyObject.wheelSpeedMultiplier;
			}
			
			// Handle ropes, keep scaling them so they stay in place with the platform they are associated with
			for(var ropeNode:PulleyRopeNode = this._ropeList.head; ropeNode; ropeNode = ropeNode.next)
			{
				if(ropeNode.pulleyRope.lastEndY != ropeNode.pulleyRope.endSpatial.y + ropeNode.pulleyRope.offsetConnection)
				{
					ropeNode.spatial.scaleY = 1 + ((ropeNode.pulleyRope.endSpatial.y + ropeNode.pulleyRope.offsetConnection - (ropeNode.pulleyRope.originalHeight + ropeNode.spatial.y)) / ropeNode.pulleyRope.originalHeight);
					ropeNode.spatial.x = ropeNode.pulleyRope.startSpatial.x;
					ropeNode.spatial.y = ropeNode.pulleyRope.startSpatial.y;
					ropeNode.pulleyRope.lastEndY = ropeNode.pulleyRope.endSpatial.y + ropeNode.pulleyRope.offsetConnection;
				}
			}
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(MassNode);
			systemManager.releaseNodeList(PulleyRopeNode);
			
			this._massList = null;
			this._ropeList = null;
			
			super.removeFromEngine(systemManager);
		}
		
		private var _massList:NodeList;
		private var _ropeList:NodeList;
	}
}