package engine.systems
{
	import ash.core.Engine;
	
	import engine.components.Spatial;
	import engine.components.SpatialWrap;
	import engine.nodes.SpatialWrapNode;
	
	import game.systems.GameSystem;
	
	public class SpatialWrapSystem extends GameSystem
	{
		public function SpatialWrapSystem()
		{
			super(SpatialWrapNode, updateNode);
		}
		
		public function updateNode(node:SpatialWrapNode, time:Number):void
		{
			if(node.spatial._invalidate)
			{
				var wrap:SpatialWrap = node.spatialWrap;
				var spatial:Spatial = node.spatial;
				var vXCheck:Number = spatial.x + node.spatialOffset.x + wrap.x + super.group.shellApi.viewportWidth / 2;
				
				if (vXCheck < -spatial.width)
				{
					wrap.x += wrap.wrapX;
				}
				else if (vXCheck > spatial.width)
				{
					wrap.x -= wrap.wrapX;
	
					if (wrap.x < 0)
					{
						wrap.x = 0;
					}
				}
				
				if(wrap.x != 0) { spatial.x += wrap.x; }
				
				var vYCheck:Number = spatial.y + node.spatialOffset.y + wrap.y + super.group.shellApi.viewportHeight / 2;
				
				if (vYCheck > spatial.height)
				{
					wrap.y -= wrap.wrapY;
				}
				else if (vYCheck < -spatial.height)
				{
					wrap.y += wrap.wrapY;
				}
				
				if(wrap.y != 0) { spatial.y += wrap.y; }
			}
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(SpatialWrapNode);
			super.removeFromEngine(systemManager);
		}
	}
}