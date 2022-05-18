package game.systems.motion
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	import engine.components.Motion;
	import game.nodes.motion.VelocityListenerNode;
	import game.systems.SystemPriorities;
	
	
	/**
	 * Watches an Entity's Motion component and dispatches a signal when it changes
	 */
	public class VelocityListenerSystem extends System
	{
		private var _nodes : NodeList;
		
		override public function addToEngine(systemsManager:Engine):void
		{
			_nodes = systemsManager.getNodeList(VelocityListenerNode);
			_nodes.nodeRemoved.add( nodeRemoved );
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function update( time : Number ) : void
		{
			var node:VelocityListenerNode;
			var motion:Motion;
			
			for ( node = _nodes.head; node; node = node.next )
			{
				motion = node.motion;
				
				// Only dispatch the signal if velocity has changed, unless it is set to always run
				if(node.velocityListener.alwaysOn)
				{
					node.velocityListener.velocityHandler.dispatch(motion.velocity);
				}
				else if(node.velocityListener.prevVelocityX != motion.velocity.x || node.velocityListener.prevVelocityY != motion.velocity.y)
				{
					node.velocityListener.velocityHandler.dispatch(motion.velocity);
				}
				
				node.velocityListener.prevVelocityX = motion.velocity.x;
				node.velocityListener.prevVelocityY = motion.velocity.y;
			}
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(VelocityListenerNode);
			_nodes = null;
		}
		
		private function nodeRemoved(node:VelocityListenerNode):void
		{
			node.velocityListener.removeSignal();
		}

	}
}
