package game.systems.entity
{
	
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import game.nodes.entity.ZDepthControlNode;
	import game.nodes.entity.ZDepthNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class ZDepthSystem extends GameSystem
	{
		public function ZDepthSystem()
		{
			super( ZDepthControlNode, updateNode );
			super._defaultPriority = SystemPriorities.render;	
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			_zNodes = systemManager.getNodeList(ZDepthNode);
		}
		
		/**
		 * Check against all of the characetrs/creatures that are not sleeping or ignoreDepth.
		 * Figures out appropriate depth and makes change. 
		 */
		public function updateNode(node:ZDepthControlNode, time:Number):void
		{
			//trace ("[ZDepthSystem] updateNode")
			// sort ZDepthNode list by zDepth value 
			_zNodes.insertionSort( sortZNodes );
			
			var container:DisplayObjectContainer = node.display.displayObject;
			var zNode:ZDepthNode;
			var currentLayerIndex:int;
			var nextLayerIndex:int;
			var prevZforDebug:int = -999
			if (!container) return
			
			for ( zNode = _zNodes.head; zNode; zNode = zNode.next )
			{
				//trace (" zNode.zDepth:" +  zNode.zDepth.z)
				//if (zNode.zDepth.z < prevZforDebug) {
					//trace ("-------- [ZDepthSystem] z depths out of order " + zNode.zDepth.z + " ---------")
				//}
				
				// The commented code below wasn't sorting, so for now just adding all children again. To do: optimize - Gabriel
				if (zNode.display) 
				{
					if (zNode.display.displayObject) container.addChild(zNode.display.displayObject)
				}
					
				//				prevZforDebug = zNode.zDepth.z
				//				//if (EntityUtils.sleeping(zNode.entity))	{ continue; }
				//				if( zNode.zDepth.ignore || !zNode.next || !container  )	{ continue; }
				//				
				//				if (zNode.display.displayObject && zNode.next.display.displayObject) {
				//					if (zNode.display.displayObject.parent && zNode.next.display.displayObject.parent) {
				//						//trace ("zNode.next.display.displayObject:" + zNode.next.display.displayObject)
				//						currentLayerIndex = container.getChildIndex( zNode.display.displayObject );
				//						nextLayerIndex = container.getChildIndex( zNode.next.display.displayObject );
				//						
				//						if( currentLayerIndex > nextLayerIndex )	// if current is greater than next, then they should swap layer order
				//						{
				//							//container.setChildIndex( zNode.next.display.displayObject, currentlayerIndex );
				//							container.swapChildrenAt( currentLayerIndex, nextLayerIndex );
				//						}
				//					}
				//				}
				
				/*
				// Example code, will see if integration works
				function sortZ (dParent:DisplayObjectContainer):void {
					for (var i:int = dParent.numChildren - 1; i > 0; i--) {
						var bFlipped:Boolean = false;
						
						for (var o:int = 0; o < i; o++) {
							if (dParent.getChildAt(o).y > dParent.getChildAt(o+1).y) {
								dParent.swapChildrenAt(o,o+1);
								bFlipped = true;
							}
						}
						if (!bFlipped)
							return;
					}
				}
				*/
			}
		}
		
		/**
		 * If the returned number is less than zero, the first node should be before the second. If it is greater than zero the second node should be before the first. If it is zero the order of the nodes doesn't matter. 
		 * @param node1
		 * @param node2
		 * @return 
		 * 
		 */
		private function sortZNodes( node1 : ZDepthNode, node2 : ZDepthNode ) : Number
		{
			if( node1.zDepth.z < node2.zDepth.z )
			{
				return -1;
			}
			else if( node1.zDepth.z > node2.zDepth.z )
			{
				return 1;
			}
			else
			{
				return 0;
			}
		}
		
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			//systemManager.releaseNodeList(ZDepthControlNode);
			systemManager.releaseNodeList(ZDepthNode);
			_zNodes = null;
			super.removeFromEngine(systemManager);
		}
		
		private var _zNodes:NodeList;	
	}
}
