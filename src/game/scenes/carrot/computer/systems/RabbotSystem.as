package game.scenes.carrot.computer.systems
{

	import engine.components.Spatial;
	import game.scenes.carrot.computer.nodes.RabbotNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	import ash.core.Engine;
	import ash.tools.ListIteratingSystem;

	public class RabbotSystem extends GameSystem
	{
		public function RabbotSystem()
		{
			super(RabbotNode, updateNode);
			super._defaultPriority = SystemPriorities.update;
		}
			     
	    private function updateNode(node:RabbotNode, time:Number):void
	    {
			var percent:Number = (node.target.target.x - node.rabbot.screenCenter) / node.rabbot.maxControlDelta;
			percent = ( percent > 1 ) ? 1 : percent;
			percent = ( percent < -1 ) ? -1 : percent;
			node.motion.velocity.x = node.rabbot.maxSpeed * percent;
		}
	}	
}
