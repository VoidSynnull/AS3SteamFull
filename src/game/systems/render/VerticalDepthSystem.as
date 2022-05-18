package game.systems.render
{
	import flash.display.DisplayObjectContainer;
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.nodes.render.VerticalDepthNode;
	import game.systems.SystemPriorities;
	
	public class VerticalDepthSystem extends System
	{
		private var nodes:NodeList;
		private var containers:Dictionary = new Dictionary(true);
		
		public function VerticalDepthSystem()
		{
			this._defaultPriority = SystemPriorities.moveComplete;
		}
		
		override public function update(time:Number):void
		{
			var container:DisplayObjectContainer;
			
			for(var node1:VerticalDepthNode = this.nodes.head; node1; node1 = node1.next)
			{
				container = node1.display.displayObject.parent;
				
				//We check Nodes with the same container/parent in one pass.
				if(!this.containers[container])
				{
					this.containers[container] = true;
					
					for(var node2:VerticalDepthNode = node1.next; node2; node2 = node2.next)
					{
						//We don't compare Nodes if they aren't in the same DisplayObjectContainer.
						if(node2.display.displayObject.parent != container) continue;
						
						var index1:int = container.getChildIndex(node1.display.displayObject);
						var index2:int = container.getChildIndex(node2.display.displayObject);
						
						//Only swap DisplayObject indices if there has been a change in y-depth compared to index.
						if(index1 > index2 && node1.spatial.y + node1.depth.offset > node2.spatial.y + node2.depth.offset) continue;
						if(index1 < index2 && node1.spatial.y + node1.depth.offset < node2.spatial.y + node2.depth.offset) continue;
						
						container.swapChildrenAt(index1, index2);
					}
				}
			}
			
			//Clear out the containers for the next update loop.
			for(container in this.containers)
			{
				delete this.containers[container];
			}
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			this.nodes = systemManager.getNodeList(VerticalDepthNode);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(VerticalDepthNode);
			this.nodes = null;
		}
	}
}