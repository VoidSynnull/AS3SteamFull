package game.scenes.viking.river.raftEddyCollision
{
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	
	public class RaftEddyCollisionSystem extends System
	{
		private var _rafts:NodeList;
		private var _eddys:NodeList;
		
		public function RaftEddyCollisionSystem()
		{
			super();
		}
		
		override public function update(time:Number):void
		{
			for(var node1:RaftNode = this._rafts.head; node1; node1 = node1.next)
			{
				if(EntityUtils.sleeping(node1.entity)) continue;
				
				if(node1.raft.lockTime > 0)
				{
					node1.raft.lockTime -= time;
					if(node1.raft.lockTime <= 0)
					{
						CharUtils.lockControls(node1.entity, false, false);
						node1.wave.dataForProperty("rotation").magnitude = 0;
					}
					break;
				}
				else
				{
					var point:Point = DisplayUtils.localToLocal(node1.display.displayObject, node1.display.displayObject.stage);
					
					for(var node2:EddyNode = this._eddys.head; node2; node2 = node2.next)
					{
						if(EntityUtils.sleeping(node2.entity)) continue;
						
						if(DisplayObject(node2.display.displayObject).hitTestPoint(point.x, point.y))
						{
							CharUtils.lockControls(node1.entity);
							node1.raft.lockTime = 2;
							
							node1.wave.dataForProperty("rotation").magnitude = 3;
							break;
						}
					}
				}
			}
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			
			this._rafts = systemManager.getNodeList(RaftNode);
			this._eddys = systemManager.getNodeList(EddyNode);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(RaftNode);
			systemManager.releaseNodeList(EddyNode);
			
			this._rafts = null;
			this._eddys = null;
			
			super.removeFromEngine(systemManager);
		}
	}
}