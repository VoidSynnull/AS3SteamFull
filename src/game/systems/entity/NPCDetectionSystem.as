package game.systems.entity
{
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import game.nodes.entity.HideNode;
	import game.nodes.entity.NPCDetectorNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	/** 
	 * @author Scott Wszalek
	 */	
	public class NPCDetectionSystem extends GameSystem
	{
		public function NPCDetectionSystem()
		{
			super(NPCDetectorNode, updateNode, addedNode);
			this._defaultPriority = SystemPriorities.resolveCollisions;
		}
		
		private function updateNode(node:NPCDetectorNode, time:Number):void
		{
			for(var hideNode:HideNode = _hideList.head; hideNode; hideNode = hideNode.next)
			{
				if(!hideNode.hide.hidden)
				{
					// Check if the npc is facing the player
					if((node.spatial.scaleX < 0 && hideNode.spatial.x > node.spatial.x) ||
						(node.spatial.scaleX >= 0 && hideNode.spatial.x < node.spatial.x))
					{
						// Check the distance to see if we are within range and make sure we are close enough on the y axis
						if(Math.abs(node.spatial.x - hideNode.spatial.x) < node.npcDetector.distance && Math.abs(node.spatial.y - hideNode.spatial.y) < (node.spatial.height + node.npcDetector.yVariant))
						{
							node.npcDetector.detected.dispatch(hideNode.entity);
						}
					}
				}
			}
		}
		
		private function addedNode(node:NPCDetectorNode):void
		{
			_hideList = systemManager.getNodeList(HideNode);	
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(HideNode);
			_hideList = null;
		}
		
		private var _hideList:NodeList;
	}
}