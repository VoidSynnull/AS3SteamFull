package game.systems.render
{
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import game.nodes.render.LightOverlayNode;
	import game.nodes.render.LightRangeNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class LightRangeSystem extends GameSystem
	{
		public function LightRangeSystem()
		{
			super(LightRangeNode, updateNode, nodeAdded);
			
			super._defaultPriority = SystemPriorities.moveComplete;
		}

		private function updateNode(node:LightRangeNode, time:Number):void
		{
			if(_lightOverlayNodes != null)
			{
				var currentPosition:Number = node.spatial.y;
				
				if(node.lightRange.horizontalRange)
				{
					currentPosition = node.spatial.x;
				}
				
				if(currentPosition > node.lightRange.min)
				{
					var delta:Number = node.lightRange.max - currentPosition;
					var factor:Number = delta / node.lightRange.range;

					LightOverlayNode(_lightOverlayNodes.head).lightOverlay.darkAlpha = node.light.darkAlpha = Math.min(node.lightRange.maxDarkAlpha, (1 - factor) * node.lightRange.baseDarkAlpha);
					node.light.lightAlpha = Math.min(node.lightRange.maxLightAlpha, (1 - factor) * node.lightRange.baseLightAlpha);
					node.light.radius = Math.max(node.lightRange.minRadius, node.lightRange.baseRadius * factor);
				}
			}
		}
		
		private function nodeAdded(node:LightRangeNode):void
		{
			node.lightRange.baseDarkAlpha = node.light.darkAlpha;
			node.lightRange.baseLightAlpha = node.light.lightAlpha;
			node.lightRange.baseRadius = node.light.radius;
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			super.removeFromEngine(systemManager);
			
			_lightOverlayNodes = null;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			_lightOverlayNodes = systemManager.getNodeList(LightOverlayNode);
			
			super.addToEngine(systemManager);
		}
		
		private var _lightOverlayNodes:NodeList;
	}
}