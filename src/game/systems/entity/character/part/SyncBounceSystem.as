package game.systems.entity.character.part
{
	import ash.core.Engine;
	import ash.core.Node;
	import ash.core.NodeList;
	
	import engine.components.Spatial;
	
	import game.components.entity.character.part.SyncBounce;
	import game.nodes.entity.character.NpcNode;
	import game.nodes.entity.character.part.SyncBounceNode;
	import game.systems.GameSystem;
	import game.util.EntityUtils;
	
	public class SyncBounceSystem extends GameSystem
	{
		public function SyncBounceSystem()
		{
			super( SyncBounceNode, updateNode );
			super.nodeAddedFunction = SBNodeAddedFunction;
		}
		
		override public function update(time:Number):void
		{
			// calculate current elapsed time
			_curTime += time;
			for( var node:Node = super.nodeList.head; node; node = node.next )
			{
				if (!EntityUtils.sleeping(node.entity))
				{
					nodeUpdateFunction(node, time);
				}
			}
		}
		
		private function SBNodeAddedFunction( node:SyncBounceNode ):void
		{
			// set start position
			node.syncBounce.startY = node.entity.get(Spatial).y;
		}
		
		override public function addToEngine( systemManager:Engine ):void
		{
			_npcNodes = systemManager.getNodeList( NpcNode );
			super.addToEngine( systemManager );
		}
		
		override public function removeFromEngine( systemManager:Engine ):void
		{
			systemManager.releaseNodeList( NpcNode );
		}
		
		private function updateNode( node:SyncBounceNode, time:Number ):void
		{
			var sync:SyncBounce = node.syncBounce;
			// set bounce based on time and radius and starting position
			node.spatial.y = sync.startY + (Math.sin(_curTime/sync.bounceTime * 2.0 * Math.PI) + 0.5) * sync.radius;
		}
		
		private var _curTime:Number = 0;
		private var _npcNodes:NodeList;
	}
}