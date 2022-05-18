package game.scenes.survival1.shared.systems
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.components.audio.Mic;
	import game.nodes.audio.MicNode;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	import game.scenes.survival1.shared.components.MicBlow;
	import game.scenes.survival1.shared.nodes.MicBlowNode;
	
	public class MicBlowSystem extends System
	{
		private var blowNodes:NodeList;
		private var micNodes:NodeList;
		
		public function MicBlowSystem()
		{
			this._defaultPriority = SystemPriorities.update;
		}
		
		override public function update(time:Number):void
		{
			/*
			There should only be 1 microphone Entity at a time, so getting the head is the only thing to do. We should
			always check if the head exists though, as the Entity could be removed, leaving the NodeList empty.
			*/
			var micNode:MicNode = micNodes.head;
			if(!micNode) return;
			
			var mic:Mic = micNode.mic;
			
			for(var node:MicBlowNode = this.blowNodes.head; node; node = node.next)
			{
				if(EntityUtils.sleeping(node.entity)) continue;
				
				var blow:MicBlow = node.blow;
				
				if(blow.hasBlown) continue;
				
				if(mic.isActive && mic.microphone.activityLevel >= blow.minActivityLevel)
				{
					blow.time += time;
					if(blow.time >= blow.waitTime)
					{
						blow.hasBlown = true;
						blow.blown.dispatch(node.entity);
					}
				}
				else
				{
					blow.time = 0;
				}
			}
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			this.blowNodes 	= systemManager.getNodeList(MicBlowNode);
			this.micNodes	= systemManager.getNodeList(MicNode);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(MicBlowNode);
			
			this.blowNodes 	= null;
			this.micNodes 	= null;
		}
	}
}