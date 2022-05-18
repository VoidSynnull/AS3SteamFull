package game.systems.entity
{
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import game.components.entity.Detector;
	import game.nodes.entity.DetectorNode;
	import game.nodes.entity.HideNode;
	import game.systems.GameSystem;
	import game.util.GeomUtils;
	
	/**
	 * @author Scott Wszalek
	 */	
	public class DetectionSystem extends GameSystem
	{
		public function DetectionSystem()
		{
			super(DetectorNode, updateNode, addedNode);
		}
		
		private function updateNode(node:DetectorNode, time:Number):void
		{
			var detector:Detector = node.detector;
			
			for(var hideNode:HideNode = _hideList.head; hideNode; hideNode = hideNode.next)
			{
				// if enemy is not hiding
				if(!hideNode.hide.hidden)
				{
					// Check distance
					if(detector.distance >= GeomUtils.dist(node.spatial.x, node.spatial.y, hideNode.spatial.x, hideNode.spatial.y))
					{					
						// Get angle of camera and hitNode
						var angleBetween:Number = GeomUtils.degreesBetween(node.spatial.x, node.spatial.y, hideNode.spatial.x, hideNode.spatial.y);
						angleBetween += detector.offset;
						
						if(angleBetween < node.spatialAddition.rotation + detector.angle && angleBetween > node.spatialAddition.rotation - detector.angle)
						{
							// Cone has hit the player, dispatch out
							detector.detectorHit.dispatch(hideNode.entity);
						}
					}					
				}
			}
		}
		
		private function addedNode(node:DetectorNode):void
		{
			_hideList = systemManager.getNodeList(HideNode);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(HideNode);
			_hideList = null;
		}
		
		private var _hideList:NodeList;
		private static const DEGRAD:Number = Math.PI/180;
	}
}