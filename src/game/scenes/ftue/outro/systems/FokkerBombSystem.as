package game.scenes.ftue.outro.systems
{
	import ash.tools.ListIteratingSystem;
	
	import game.scenes.ftue.outro.groups.FokkerBombGroup;
	import game.scenes.ftue.outro.nodes.FokkerBombNode;
	
	public class FokkerBombSystem extends ListIteratingSystem
	{
		public function FokkerBombSystem()
		{
			super(FokkerBombNode, onUpdateNode);
		}
		
		private function onUpdateNode(node:FokkerBombNode, time:Number):void
		{
			if(node.hit.collided){
				FokkerBombGroup(group).hitPlayer();
			}
		}
	}
}