package game.scenes.viking.shared.dodoCluster
{
	import flash.geom.Point;
	
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.Utils;
	
	public class DodoClusterSystem extends GameSystem
	{
		public function DodoClusterSystem()
		{
			super(DodoClusterNode, updateNode);
			this._defaultPriority = SystemPriorities.move;
		}
		
		private function updateNode(node:DodoClusterNode, time:Number):void
		{
			node.cluster.offsetElapsedTime += time;
			
			if(node.cluster.offsetElapsedTime >= node.cluster.offsetChangeTime)
			{
				node.cluster.offsetElapsedTime -= node.cluster.offsetChangeTime;
				
				if(!node.target.offset)
				{
					node.target.offset = new Point();
				}
				
				node.target.offset.x = Utils.randNumInRange(-node.cluster.offset, node.cluster.offset);
			}
		}
	}
}