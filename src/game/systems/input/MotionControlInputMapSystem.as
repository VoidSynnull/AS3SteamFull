package game.systems.input
{
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import game.components.input.Input;
	import game.components.motion.MotionControl;
	import game.nodes.input.InputNode;
	import game.nodes.input.MotionControlInputMapNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	/**
	 * Updates MotionControl component from Input
	 */
	public class MotionControlInputMapSystem extends GameSystem
	{
		public function MotionControlInputMapSystem()
		{
			super(MotionControlInputMapNode, updateNode);
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			
			_inputNodes = systemManager.getNodeList(InputNode);
		}
		
		public function updateNode(node:MotionControlInputMapNode, time:Number):void
		{
			if(_inputNodes.head)
			{
				var input:Input = InputNode(_inputNodes.head).input;
				var motionControl:MotionControl = node.motionControl;
				
				if(!motionControl.lockInput)
				{
					motionControl.inputStateChange = ( motionControl.inputActive != input.inputActive );
					motionControl.inputActive = input.inputActive;
					motionControl.inputStateDown = input.inputStateDown;
				}
				else
				{
					motionControl.inputStateChange = false;
				}
			}
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(InputNode);
			systemManager.releaseNodeList(MotionControlInputMapNode);
			_inputNodes = null;
			
			super.removeFromEngine(systemManager);
		}
		
		private var _inputNodes:NodeList;
	}
}