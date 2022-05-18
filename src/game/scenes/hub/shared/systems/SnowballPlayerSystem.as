package game.scenes.hub.shared.systems
{
	import ash.tools.ListIteratingSystem;
	
	import game.scenes.hub.shared.nodes.SnowballPlayerNode;
	
	public class SnowballPlayerSystem extends ListIteratingSystem
	{
		public function SnowballPlayerSystem()
		{
			super(SnowballPlayerNode, updateNode);
		}
		
		private function updateNode(node:SnowballPlayerNode, time:Number):void
		{
			if (node.fsmControl.state.type == "duck" && !node.snowballPlayer.ducking){
				node.snowballPlayer.duck();
			} else if(node.fsmControl.state.type != "duck" && node.snowballPlayer.ducking){
				node.snowballPlayer.reset();
			}
		}
	}
}