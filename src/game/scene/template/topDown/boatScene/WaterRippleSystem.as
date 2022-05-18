package game.scene.template.topDown.boatScene
{
	import game.managers.EntityPool;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class WaterRippleSystem extends GameSystem
	{
		public function WaterRippleSystem(pool:EntityPool)
		{
			super(WaterRippleNode, updateNode);
			_pool = pool;
			super._defaultPriority = SystemPriorities.moveComplete;
		}
		
		private function updateNode(node:WaterRippleNode, time:Number):void
		{
			var motionFactor:Number = 1 - node.waterRipple.motionFactor;
			var growRate:Number = node.waterRipple.baseGrowthRate + node.waterRipple.growRateMultiplier * motionFactor;
			var fadeRate:Number = node.waterRipple.motionBasedFadeRate * motionFactor;
			var timeFactor:Number = Math.min(1, time / _baseTime);
			
			node.spatial.scaleX += growRate * timeFactor;
			node.spatial.scaleY = node.spatial.scaleX;
			node.display.alpha -= (node.waterRipple.baseFadeRate + fadeRate) * timeFactor;
			
			if(node.display.alpha <= 0)
			{
				//node.entity.group.removeEntity(node.entity, true);
				
				node.entity.sleeping = true;
				node.entity.ignoreGroupPause = true;
				_pool.release(node.entity, "wake");
			}
		}
		
		private var _pool:EntityPool;
		private var _baseTime:Number = 1 / 60;
	}
}