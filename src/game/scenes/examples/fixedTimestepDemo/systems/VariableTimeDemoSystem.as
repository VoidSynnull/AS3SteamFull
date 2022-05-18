package game.scenes.examples.fixedTimestepDemo.systems
{
	import flash.display.MovieClip;
	
	import game.scenes.examples.fixedTimestepDemo.nodes.VariableTimeDemoNode;
	import game.systems.GameSystem;
	
	public class VariableTimeDemoSystem extends GameSystem
	{
		public function VariableTimeDemoSystem()
		{
			super(VariableTimeDemoNode, updateNode);
		}
		
		private function updateNode(node:VariableTimeDemoNode, time:Number):void
		{
			node.variableTime.totalUpdates++;
			MovieClip(node.display.displayObject).total.text = node.variableTime.totalUpdates;
		}
	}
}