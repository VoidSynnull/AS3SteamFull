package game.systems.motion.nape
{
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.components.Spatial;
	
	import game.data.motion.time.FixedTimestep;
	import game.nodes.motion.nape.NapeMagnetNode;
	import game.nodes.motion.nape.NapeMagneticNode;
	import game.systems.GameSystem;
	import game.util.GeomUtils;
	
	import nape.geom.Vec2;
	
	public class NapeMagnetSystem extends GameSystem
	{
		public function NapeMagnetSystem()
		{
			super(NapeMagnetNode, updateNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			
			_magneticNodes = systemManager.getNodeList(NapeMagneticNode);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			super.removeFromEngine(systemManager);
			
			_magneticNodes = null;
		
			systemManager.releaseNodeList(NapeMagneticNode);
		}
		
		private function updateNode(node:NapeMagnetNode, time:Number):void
		{
			var magnetSpatial:Spatial = node.spatial;
			var magneticSpatial:Spatial;
			var distance:Number;
			
			for (var magneticNode:NapeMagneticNode = _magneticNodes.head; magneticNode; magneticNode = magneticNode.next )
			{
				magneticSpatial = magneticNode.spatial;
				var dx:Number = magnetSpatial.x - magneticSpatial.x;	
				var dy:Number = magnetSpatial.y - magneticSpatial.y;
				
				distance = GeomUtils.distFromDelta(dx, dy);
				
				if(node.magnet.active && node.magnet.field > distance)
				{
					var factor:Number = (node.magnet.field - distance) / node.magnet.field;
					var polarity:Number = 1;
					
					if(node.magnet.polarity != magneticNode.magnetic.polarity)
					{
						polarity = -1;
					}
					
					var totalForce:Number = (node.magnet.force * factor) * polarity;
					var angle:Number = Math.atan2(dy, dx);
					var cosAngle:Number = Math.cos(angle);
					var sinAngle:Number = Math.sin(angle);
					var ax:Number = cosAngle * totalForce;
					var ay:Number = sinAngle * totalForce;
					
					// if this entity is missing a NapeMotion component we apply the force to standard motion.
					if(magneticNode.napeMotion == null)
					{
						magneticNode.motion.acceleration.x = ax * time;
						magneticNode.motion.acceleration.y = ay * time;
					}
					else
					{
						var force:Vec2 = Vec2.weak(ax, ay);
						magneticNode.napeMotion.body.applyImpulse(force.muleq(time), null, true);	
					}
				}
			}
		}
		
		private var _magneticNodes:NodeList;
	}
}