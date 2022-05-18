package game.systems.motion
{
	import ash.core.Engine;
	
	import engine.components.Spatial;
	
	import game.components.motion.Edge;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.motion.ScaleTargetNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class ScaleSystem extends GameSystem
	{
		public function ScaleSystem()
		{
			super(ScaleTargetNode, updateNode, nodeAdded);
			super._defaultPriority = SystemPriorities.update;
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		private function nodeAdded(node:ScaleTargetNode):void
		{
			if(isNaN(node.scaleTarget.target))
			{
				node.scaleTarget.target = node.spatial.scale;
			}
		}
		
		private function updateNode(node:ScaleTargetNode, time:Number):void
		{
			var spatial:Spatial = node.spatial;
			var scaleTarget:Number = node.scaleTarget.target;
			
			if(spatial.scale != scaleTarget)
			{
				var scaleDelta:Number = scaleTarget - spatial.scale;
				var newScale:Number;
				
				if(Math.abs(scaleDelta) <= node.scaleTarget.scaleStep * time)
				{
					newScale = scaleTarget;
				}
				else
				{
					if(scaleTarget < spatial.scale)
					{
						newScale = spatial.scale - node.scaleTarget.scaleStep * time;
					}
					else if(scaleTarget > spatial.scale)
					{
						newScale = spatial.scale + node.scaleTarget.scaleStep * time;
					}
				}
				
				var edge:Edge = node.entity.get(Edge);
				
				if(edge != null && spatial.scale != 0)
				{
					//For cases where the spatial y of the entity is not equal to the bottom of their edge,
					//we have to shift the spatial y to account for the difference in scale.
					spatial.y += Math.ceil(edge.rectangle.bottom - edge.unscaled.bottom * newScale);
				}
				
				spatial.scale = newScale;
			}
		}
		
		override public function removeFromEngine(systemsManager:Engine) : void
		{
			systemsManager.releaseNodeList(ScaleTargetNode);
		}
	}
}