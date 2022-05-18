package game.scenes.map.map.systems
{
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.map.map.nodes.MapCloudNode;
	import game.scenes.map.map.nodes.MapControlNode;
	import game.systems.SystemPriorities;
	
	import org.osflash.signals.Signal;
	
	public class MapMovementSystem extends System
	{
		private var maps:NodeList;
		private var clouds:NodeList;
		
		private var scale:Number;
		
		public var resetCloud:Signal = new Signal(Entity);
		
		public function MapMovementSystem()
		{
			this._defaultPriority = SystemPriorities.update;
		}
		
		override public function update(time:Number):void
		{
			var control:MapControlNode = this.maps.head;
			if(!control) return;
			
			this.updateClouds(control);
		}
		
		private function updateClouds(control:MapControlNode):void
		{
			for(var node:MapCloudNode = this.clouds.head; node; node = node.next)
			{
				if(control.book.invalidate) node.cloud.minX = -control.addition.x - 150;
				
				if(node.spatial.x < node.cloud.minX || node.spatial.x > node.cloud.minX + this.group.shellApi.viewportWidth + 300)
				{
					node.spatial.x = node.cloud.minX + this.group.shellApi.viewportWidth + 300;
					this.resetCloud.dispatch(node.entity);
				}
			}
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			this.maps	= systemManager.getNodeList(MapControlNode);
			this.clouds = systemManager.getNodeList(MapCloudNode);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(MapControlNode);
			systemManager.releaseNodeList(MapCloudNode);
			
			this.maps	= null;
			this.clouds = null;
		}
	}
}