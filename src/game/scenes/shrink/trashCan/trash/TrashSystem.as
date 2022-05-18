package game.scenes.shrink.trashCan.trash
{
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import game.components.hit.Wall;
	import game.components.motion.WaveMotion;
	import game.data.WaveMotionData;
	import game.systems.GameSystem;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PlatformUtils;
	
	import org.osflash.signals.Signal;
	
	public class TrashSystem extends GameSystem
	{
		public var squash:Signal;
		
		public function TrashSystem()
		{
			squash = new Signal(Entity, Entity);
			super(TrashNode, updateNode);
		}
		
		public function updateNode(node:TrashNode, time:Number):void
		{
			if(!node.hit.isHit)// not in contact with a platform
			{
				if(!node.trash.falling && !node.trash.shaking)// if im not already falling and i have not started shaking
					shake(node);
				else
				{
					if(node.trash.shaking)// if i am shaking
					{
						node.trash.time -= time;
						// and i have shaked enough
						if(node.trash.time <= 0)
							drop(node);// fall
						else if(!PlatformUtils.isMobileOS)
							node.shake.data[0].magnitude = node.trash.time / node.trash.shakeTime * node.trash.shakeIntensity;
					}
				}
			}
			else
			{
				if(node.trash.falling)// upon landing check to see if i hit the player
				{
					var player:Entity = group.getEntityById("player");
					var display:DisplayObject = EntityUtils.getDisplayObject(player);
					var localPos:Point = DisplayUtils.localToLocal(display, display.stage);
					
					group.shellApi.triggerEvent("trash_land");
					
					if(DisplayObject(node.display.displayObject).hitTestPoint(localPos.x, localPos.y))
						squash.dispatch(node.entity, player);
					else
						node.entity.add(new Wall());// if i dont squash the player become a wall again
					node.trash.falling = false;
				}
				if(node.trash.shaking)
				{
					var shakeMotion:WaveMotion = node.shake;
					var data:WaveMotionData = shakeMotion.data[0];
					data.magnitude = 0;
					node.trash.shaking = false;
				}
			}
		}
		// shake shake shake
		private function shake(node:TrashNode):void
		{
			node.trash.shaking = true;
			node.trash.time = node.trash.shakeTime;
		}
		
		private function drop(node:TrashNode):void
		{
			var shakeMotion:WaveMotion = node.shake;
			var data:WaveMotionData = shakeMotion.data[0];
			data.magnitude = 0;
			node.trash.shaking = false;
			node.trash.falling = true;
			node.trash.time = 0;
			node.motion.acceleration.y = MotionUtils.GRAVITY;
			node.entity.remove(Wall);//wall pushes the player out of the box, so would never achieve the squash
		}
	}
}