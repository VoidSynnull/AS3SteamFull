package game.scenes.viking.river.depthScale
{
	import game.systems.GameSystem;
	import game.util.Utils;
	
	public class DepthScaleSystem extends GameSystem
	{
		public function DepthScaleSystem()
		{
			super(DepthScaleNode, updateNode);
		}
		
		private function updateNode(node:DepthScaleNode, time:Number):void
		{
			var scale:Number = Utils.convertRatio(node.spatial.y, node.depth._minY, node.depth._maxY, node.depth._minScale, node.depth._maxScale);
			
			if(node.depth._limit)
			{
				if(scale < node.depth._minScale)
				{
					scale = node.depth._minScale;
				}
				else if(scale > node.depth._maxScale)
				{
					scale = node.depth._maxScale;
				}
			}
			
			node.spatial.scale = scale;
		}
	}
}