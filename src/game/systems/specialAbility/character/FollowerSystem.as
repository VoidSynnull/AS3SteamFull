package game.systems.specialAbility.character
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.components.specialAbility.character.Follower;
	import game.nodes.specialAbility.character.FollowerNode;
	import game.systems.SystemPriorities;

	public class FollowerSystem extends System
	{
		private var _nodes:NodeList;
		
		override public function addToEngine(systemsManager:Engine):void
		{
			_nodes = systemsManager.getNodeList(FollowerNode);
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function update( time : Number ) : void
		{
			var node:FollowerNode;
			var follower:Follower;
			var spatial:Spatial
			
			for ( node = _nodes.head; node; node = node.next )
			{
				follower = node.follower;
				spatial = node.targetSpatial.target;
				
				follower.t += follower.speed;
				var delX:Number = (spatial.x + follower.offsetX + 50 *Math.abs(spatial.scaleX)/spatial.scaleX) - node.spatial.x;
				var delY:Number = (spatial.y + follower.offsetY - 70) -  node.spatial.y;
				
				follower.accelX = delX/80;
				follower.accelY = delY/80;
				follower.velX += follower.accelX;
				follower.velY += follower.accelY;
				follower.velX *= follower.damp;
				follower.velY *= follower.damp;
				node.spatial.x += follower.velX;
				node.spatial.y += follower.velY;
				node.spatial.rotation = follower.velX*3;
				follower.speed = Math.sqrt(follower.velX*follower.velX + follower.velY*follower.velY)/20 + 0.5;
				var distance:Number = Math.sqrt(delX*delX + delY*delY);
				if (distance < 5) {
					pickTarget(node);
				}
				
				var sideX:Number = node.spatial.x - spatial.x;
				//trace(sideX);
				if ( follower.flipDisabled )
					return;
				
				if(sideX > 0 && node.spatial.scaleX < 0)
				{
					node.spatial.scaleX *= -1;
					if ( follower.flipClip != null )
						follower.flipClip.scaleX = 1;
					if (follower.swapTimeline)
						follower.swapTimeline.gotoAndStop(0);
				}
				else if(sideX < 0 && node.spatial.scaleX > 0)
				{
					node.spatial.scaleX *= -1;
					if ( follower.flipClip != null )
						follower.flipClip.scaleX = -1;
					if (follower.swapTimeline)
						follower.swapTimeline.gotoAndStop(1);
				}
			}
		}
		
		private function pickTarget(node:FollowerNode):void
		{
			node.follower.offsetX = Math.random()*40 - 20;
			node.follower.offsetY = Math.random()*40 - 20;
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(FollowerNode);
			_nodes = null;
		}
	}
}