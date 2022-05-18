package game.scenes.survival1.shared.systems
{
	import flash.geom.Point;
	
	import engine.components.Spatial;
	
	import game.data.motion.time.FixedTimestep;
	import game.scenes.survival1.shared.nodes.WindFlagNode;
	import game.systems.GameSystem;
	import game.util.PointUtils;
	import game.util.TweenUtils;
	
	public class WindFlagSystem extends GameSystem
	{
		public function WindFlagSystem()
		{
			super(WindFlagNode, updateNode);
			super.fixedTimestep = FixedTimestep.ANIMATION_TIME;
		}
		
		public function updateNode(node:WindFlagNode, time:Number):void
		{
			var windVelocity:Point = node.windFlag.wind.getWindVelocity();
			if(windVelocity.x >= 0 && node.windFlag.windBlock.left || windVelocity.x < 0 && node.windFlag.windBlock.right)
			{
				if(!node.windFlag.blocked)
				{
					TweenUtils.entityTo(node.entity, Spatial, 1, {rotation:90});
					node.flag.whipSpeed = 1;
					node.windFlag.blocked = true;
				}
				return;
			}
			node.windFlag.blocked = false;
			var windDirection:Number = PointUtils.getRadiansOfTrajectory(windVelocity) * 180 / Math.PI;
			TweenUtils.entityTo(node.entity, Spatial, 1, {rotation:windDirection});
			node.flag.whipSpeed = node.windFlag.wind.windVelocity * node.windFlag.windToFlagScale;
		}
	}
}