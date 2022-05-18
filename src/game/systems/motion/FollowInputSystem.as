package game.systems.motion
{
	import ash.core.Engine;
	import ash.tools.ListIteratingSystem;
	
	import game.nodes.motion.FollowInputNode;
	import game.util.Utils;
	import game.systems.SystemPriorities;
	
	/**
	 * Adjusts target for camera when target is mouse input
	 */
	public class FollowInputSystem extends ListIteratingSystem
	{
		public function FollowInputSystem()
		{
			super(FollowInputNode, updateNode);
			super._defaultPriority = SystemPriorities.moveControl;
		}
		
		public function updateNode(node:FollowInputNode, time:Number):void
		{
			var deltaX:Number = node.input.target.x - node.spatial.x;
			var deltaY:Number = node.input.target.y - node.spatial.y;
			var rate:Number = Utils.getVariableTimeEase(node.followInput.rate, time);
			
			node.spatial.x += deltaX * rate;
			node.spatial.y += deltaY * rate;
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(FollowInputNode);
			
			super.removeFromEngine(systemManager);
		}
	}
}