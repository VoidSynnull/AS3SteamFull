package game.scenes.survival2.fishingHole.fish
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.scenes.survival2.shared.nodes.HookNode;
	import game.systems.SystemPriorities;
	import game.util.GeomUtils;
	import game.util.Utils;
	
	public class FishableSystem extends System
	{
		private var fishNodes:NodeList;
		private var hookNodes:NodeList;
		
		
		public function FishableSystem()
		{
			this._defaultPriority = SystemPriorities.update;
		}
		
		override public function update(time:Number):void
		{
			//Should only be one hook.
			var hookNode:HookNode = this.hookNodes.head;
			
			for(var fishNode:FishableNode = this.fishNodes.head; fishNode; fishNode = fishNode.next)
			{
				var fish:Fishable = fishNode.fish;
				
				switch(fish.state)
				{
					case fish.TREADING_STATE:
						if( !this.bait(fishNode, hookNode, time) )
						{
							fish.time += time;
							if(fish.time >= fish.wait)
							{
								this.swim(fishNode);
							}
						}
						break;
					
					case fish.SWIMMING_STATE:
						if( !this.bait(fishNode, hookNode, time) )
						{
							if(GeomUtils.distSquared(fishNode.spatial.x, fishNode.spatial.y, fish.target.x, fish.target.y) < fish.minDistance * fish.minDistance)
							{
								fish.state = fish.TREADING_STATE;
								fishNode.motion.velocity.setTo(0, 0);
							}
						}
						break;
					
					case fish.BAIT_STATE:
						if(hookNode)
						{
							if(Math.abs(fishNode.spatial.y - hookNode.spatial.y) < 10)
							{
								fishNode.motion.velocity.setTo(0, 0);
							}
						}
						break;
				}
			}
		}
		
		private function swim(node:FishableNode):void
		{
			node.fish.time 		= 0;
			node.fish.wait		= Utils.randNumInRange(2, 4);
			node.fish.state 	= node.fish.SWIMMING_STATE;
			node.fish.target 	= GeomUtils.getRandomPointInRectangle(node.fish.swimArea);
			
			var radians:Number 		= Math.atan2(node.fish.target.y - node.spatial.y, node.fish.target.x - node.spatial.x);
			var velocity:Number 	= Utils.randNumInRange(120, 160);
			node.motion.velocity.x 	= velocity * Math.cos(radians);
			node.motion.velocity.y 	= velocity * Math.sin(radians);
			
			if(node.motion.velocity.x > 0)
			{
				if(!node.fish.reverseX && node.spatial.scaleX < 0) 	node.spatial.scaleX *= -1;
				if(node.fish.reverseX && node.spatial.scaleX > 0) 	node.spatial.scaleX *= -1;
			}
			else if(node.motion.velocity.x < 0)
			{
				if(!node.fish.reverseX && node.spatial.scaleX > 0) 	node.spatial.scaleX *= -1;
				if(node.fish.reverseX && node.spatial.scaleX < 0) 	node.spatial.scaleX *= -1;
			}
		}
		
		/**
		 * Check if fish has come into contact with bait/hook 
		 * @param fishNode
		 * @param hookNode
		 * @param time
		 * 
		 */
		private function bait(fishNode:FishableNode, hookNode:HookNode, time:Number):Boolean
		{
			if(!hookNode) return false;
			
			var fish:Fishable = fishNode.fish;
			
			if(fish.ignoreBait)
			{
				fish.baitTime += time;
				if(fish.baitTime >= fish.baitWait)
				{
					fish.baitTime = 0;
					fish.ignoreBait = false;
				}
			}
			else
			{
				if(fish.state != fish.BAIT_STATE)
				{
					var distanceSquared:Number = GeomUtils.distSquared(fishNode.spatial.x, fishNode.spatial.y, hookNode.spatial.x, hookNode.spatial.y);
					
					if(distanceSquared < 50 * 50)
					{
						fish.time 		= 0;
						fish.state 		= fish.BAIT_STATE;
						fishNode.motion.velocity.setTo(0, 0);
						fishNode.motion.velocity.y = (fishNode.spatial.y < hookNode.spatial.y) ? 10 : -10;
						
						var timeline:Timeline = fishNode.timeline;
						if(fish.bait == hookNode.hook.bait)
						{
							timeline.gotoAndPlay("rightBait");
							timeline.handleLabel("rightBaitEnd", Command.create(this.onRightBaitEnd, fishNode));
						}
						else
						{
							timeline.gotoAndPlay("wrongBait");
							timeline.handleLabel("wrongBaitEnd", Command.create(this.onWrongBaitEnd, fishNode));
						}
						return true;
					}
				}
			}
			return false;
		}
		
		private function onRightBaitEnd(node:FishableNode):void
		{
			node.hookable.bait = "worms";
		}
		
		private function onWrongBaitEnd(node:FishableNode):void
		{
			node.fish.ignoreBait 	= true;
			node.fish.state 		= node.fish.TREADING_STATE;
		}
		
		private function fishNodeAdded(node:FishableNode):void
		{
			var fish:Fishable 	= node.fish;
			fish.target 	= GeomUtils.getRandomPointInRectangle(fish.swimArea);
			
			node.spatial.x = fish.target.x;
			node.spatial.y = fish.target.y;
		}
		
		private function hookNodeRemoved(node:HookNode):void
		{
			for(var fishNode:FishableNode = this.fishNodes.head; fishNode; fishNode = fishNode.next)
			{
				if(fishNode.fish.state == fishNode.fish.BAIT_STATE)
				{
					fishNode.fish.state = fishNode.fish.TREADING_STATE;
				}
			}
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			this.fishNodes = systemManager.getNodeList(FishableNode);
			this.hookNodes = systemManager.getNodeList(HookNode);
			
			for(var fishNode:FishableNode = this.fishNodes.head; fishNode; fishNode = fishNode.next)
			{
				this.fishNodeAdded(fishNode);
			}
			this.fishNodes.nodeAdded.add(this.fishNodeAdded);
			
			this.hookNodes.nodeRemoved.add(this.hookNodeRemoved);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(FishableNode);
			
			this.fishNodes = null;
			this.hookNodes = null;
		}
	}
}