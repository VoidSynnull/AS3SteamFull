package game.scene.template.topDown.boatScene
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.DisplayGroup;
	
	import game.components.hit.MovieClipHit;
	import game.managers.EntityPool;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	
	public class BoatWakeSystem extends GameSystem
	{
		public function BoatWakeSystem(pool:EntityPool)
		{
			super(BoatWakeNode, updateNode);
			_pool = pool;
			super._defaultPriority = SystemPriorities.moveComplete;
		}
		
		private function updateNode(node:BoatWakeNode, time:Number):void
		{
			var timeFactor:Number = 1 - Math.min(1, time / _baseTime);
			
			node.boatWake.waitTime += time;
			
			var motionFactor:Number = (node.motion.maxVelocity.length - node.motion.velocity.length) / node.motion.maxVelocity.length;
			
			motionFactor = Math.max(0, motionFactor);
			
			var wait:Number = node.boatWake.baseWaitTime + (node.boatWake.motionBasedWaitTime * motionFactor) + timeFactor;

			if(node.boatWake.waitTime > wait)
			{
				node.boatWake.waitTime = 0;
				addRipple(node, motionFactor);
			}
		}
		
		private function addRipple(node:BoatWakeNode, motionFactor:Number):void
		{			
			var entity:Entity = _pool.request("wake");
			var motion:Motion;
			var spatial:Spatial;
			var hit:MovieClipHit;
			var display:Display;
			var waterRipple:WaterRipple;
			
			if(entity == null)
			{
				entity = new Entity();
				waterRipple = new WaterRipple();
				spatial = new Spatial();
				
				entity.add(waterRipple);
				entity.add(spatial);
				
				EntityUtils.loadAndSetToDisplay(node.boatWake.container, node.boatWake.url, entity, DisplayGroup(super.group));
				
				super.group.addEntity(entity);
			}
			else
			{
				display = entity.get(Display);
				spatial = entity.get(Spatial);
				waterRipple = entity.get(WaterRipple);
				
				entity.sleeping = false;
				entity.ignoreGroupPause = true;
				// wait for the renderSystem to display it so it won't appear until its been positioned.
				display.displayObject.visible = false;
				display.alpha = 1;
				
				// move the newest ripple to the top of the display
				var container:DisplayObjectContainer = display.displayObject.parent;
				container.setChildIndex(display.displayObject, container.numChildren - 1);
			}
			
			waterRipple.motionFactor = motionFactor;
			
			spatial.x = node.spatial.x;
			spatial.y = node.spatial.y;
			spatial.rotation = node.spatial.rotation;
			spatial.scaleX = node.boatWake.rippleScaleX;
			spatial.scaleY = node.boatWake.rippleScaleY;
		}
		
		private var _pool:EntityPool;
		private var _baseTime:Number = 1 / 60;
	}
}