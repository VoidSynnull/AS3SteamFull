/**
 * Maps the down state of the mouse and it's position to the target of an input component.
 */

package game.systems.input
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.components.input.Input;
	import game.nodes.input.InputNode;
	import game.systems.SystemPriorities;

	/**
	 * Links an input entity to the input, propagating dispatches and updating position.
	 * For web the input is the mouse, tablet may be different.
	 */
	public class InputMapSystem extends System
	{
		override public function addToEngine(systemManager:Engine):void
		{
			_nodes = systemManager.getNodeList(InputNode);
			_nodes.nodeRemoved.add( nodeRemoved );
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function update(time:Number):void
		{
			var node:InputNode;
			var input:Input;
			
			for (node = _nodes.head; node; node = node.next)
			{
				input = node.input;
				
				if(!input.lockInput)
				{
					if(input.inputStateChange)
					{
						if(input.inputStateDown)
						{
							input.inputActive = true;
							input.inputDown.dispatch(input);
						}
						else
						{
							input.inputActive = false;
							input.inputUp.dispatch(input);
						}
						
						input.inputStateChange = false;
					}
				}
				
				if(!input.lockPosition)
				{
					input.target.x = input.container.mouseX;
					input.target.y = input.container.mouseY;
					
					// the flash player positions the mouse at 5,5 when offscreen.
					if(input.container.mouseX == 5 && input.container.mouseY == 5)
					{
						input.offscreen = true;
					}
					else
					{
						input.offscreen = false;
					}
				}
			}
		}
					
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(InputNode);
			_nodes = null;
		}
				
		private function nodeRemoved(node:InputNode):void
		{
			node.input.removeAllSignals();
		}
		
		private var _nodes:NodeList;
	}
}
