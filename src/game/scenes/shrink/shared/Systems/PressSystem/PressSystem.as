package game.scenes.shrink.shared.Systems.PressSystem
{
	import game.components.hit.EntityIdList;
	import game.data.motion.time.FixedTimestep;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class PressSystem extends GameSystem
	{
		public function PressSystem()
		{
			super( PressNode, updateNode );
			super._defaultPriority = SystemPriorities.checkCollisions;
			
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		public function updateNode(node:PressNode, time:Number):void
		{
			var entityIdList:EntityIdList = node.press.hitNode.idList;
			
			if(entityIdList.entities.length > 0)
				node.press.pressing = true;
			else
				node.press.pressing = false;
			
			if(node.press.pressing && node.press.locked && !node.press.autoReleased && !node.press.atBottom)
			{
				if(!node.press.gave && node.spatial.y > node.press.upAndDownLimits.x + node.press.give)
				{
					node.press.pressed.dispatch(node.entity);
					node.press.autoReleased = true;
					node.press.gave = true;
				}
			}
			
			if(node.press.pressing && !node.press.atBottom && !node.press.autoReleased && !node.press.gave && node.motion.velocity.y >= 0 )
			{
				node.press.atTop = false;
				node.motion.velocity.y = node.press.pressVelocity;
			}
			
			if(node.press.atBottom && node.press.forceRelease)
			{
				node.press.time += time;
				if(node.press.time > node.press.autoReleaseTime)
				{
					node.press.autoReleased = true;
					node.press.time = 0;
				}
				else
					return;
			}
			
			if(!node.press.pressing && !node.press.atTop && !node.press.locked || node.press.autoReleased)
			{
				node.press.atBottom = false;
				node.motion.velocity.y = -node.press.releaseVelocity;
			}
			
			if(node.spatial.y > node.press.upAndDownLimits.y)
			{
				node.motion.velocity.y = 0;
				node.spatial.y = node.press.upAndDownLimits.y;
				node.press.atBottom = true;
				node.press.pressed.dispatch(node.entity);
			}
			
			if(!node.press.pressing && node.press.atTop || !node.press.locked && node.press.gave)
			{
				node.press.time += time;
				if(node.press.time > 1)
				{
					node.press.gave = false;
					node.press.time = 0;
				}
			}
			
			if(node.spatial.y < node.press.upAndDownLimits.x)
			{
				node.motion.velocity.y = 0;
				node.spatial.y = node.press.upAndDownLimits.x;
				node.press.atTop = true;
				node.press.autoReleased = false;
				node.press.released.dispatch(node.entity);
			}
		}
	}
}