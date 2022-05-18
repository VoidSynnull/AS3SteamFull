package game.scenes.survival1.shared.systems
{
	import engine.components.Spatial;
	
	import game.scenes.survival1.shared.nodes.WindFlagScaleNode;
	import game.systems.GameSystem;
	import game.util.TweenUtils;
	
	public class WindFlagScaleSystem extends GameSystem
	{
		public function WindFlagScaleSystem()
		{
			super(WindFlagScaleNode, updateNode);
			super.fixedTimestep = 1/15;
		}
		
		public function updateNode(node:WindFlagScaleNode, time:Number):void
		{
			if(node.windFlag.wind.windVelocity >= 0 && node.windFlag.windBlock.left || node.windFlag.wind.windVelocity < 0 && node.windFlag.windBlock.right)
			{
				if(!node.windFlag.blocked)
				{
					TweenUtils.entityTo(node.entity, Spatial, 1, {scaleX:.01});
					node.windFlag.blocked = true;
				}
				return;
			}
			node.windFlag.blocked = false;
			var scale:Number = node.windFlag.wind.windVelocity / node.windFlag.wind.maxStrongWind;
			var scaleDirection:int = 1;
			if(scale < 0) 
				scaleDirection = -1;
			scale = Math.pow(Math.abs(scale), node.windFlag.windToFlagScale) * scaleDirection;
			node.spatial.scaleX = scale;
		}
	}
}