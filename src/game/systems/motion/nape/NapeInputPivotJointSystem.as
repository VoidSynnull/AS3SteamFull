package game.systems.motion.nape
{
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import game.components.input.Input;
	import game.nodes.input.InputNode;
	import game.nodes.motion.NapePivotJointNode;
	import game.systems.GameSystem;
	
	// could probably replace this system with a generic follower setup, but for now this works...
	public class NapeInputPivotJointSystem extends GameSystem
	{
		public function NapeInputPivotJointSystem()
		{
			super(NapePivotJointNode, updateNode);
		}
		
		public function updateNode(napePivotJointNode:NapePivotJointNode, time:Number) : void
		{
			if(napePivotJointNode.napePivotJoint.pivotJoint.active)
			{
				if(_input == null)
				{
					_input = InputNode(_inputNodes.head).input;
				}
				
				var targetX:Number = super.group.shellApi.globalToScene(_input.target.x, "x");
				var targetY:Number = super.group.shellApi.globalToScene(_input.target.y, "y");
				
				napePivotJointNode.napePivotJoint.pivotJoint.anchor1.setxy(targetX, targetY);
			}
		}
		
		override public function addToEngine(systemsManager:Engine):void
		{
			super.addToEngine(systemsManager);
			_inputNodes = systemManager.getNodeList(InputNode);
		}
		
		override public function removeFromEngine(systemsManager:Engine):void
		{
			super.removeFromEngine(systemsManager);
			systemsManager.releaseNodeList(NapePivotJointNode);
			
			_input = null;
			_inputNodes = null;
		}
		
		private var _input:Input;
		private var _inputNodes:NodeList;
	}
}