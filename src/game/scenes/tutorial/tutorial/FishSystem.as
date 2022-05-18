package game.scenes.tutorial.tutorial
{
	import engine.components.Id;
	
	import game.systems.GameSystem;
	
	public class FishSystem extends GameSystem
	{
		public function FishSystem()
		{
			super(FishNode, updateNode);
		}
		
		public function updateNode(node:FishNode, time:Number):void
		{
			node.fish.period += node.fish.periodIncrement;
			node.spatial.x = 100 * Math.sin(node.fish.period + node.fish.periodOffset);
			node.spatial.scaleX = node.fish.direction * 1 * Math.cos(node.fish.period + node.fish.periodOffset);
			node.spatial.rotation = 10 * Math.sin(node.fish.period * 4);
		}
	}
}