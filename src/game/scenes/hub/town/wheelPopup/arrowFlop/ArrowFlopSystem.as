package game.scenes.hub.town.wheelPopup.arrowFlop
{
	import game.systems.GameSystem;
	
	public class ArrowFlopSystem extends GameSystem
	{
		public function ArrowFlopSystem()
		{
			super(ArrowFlopNode, updateNode);
		}
		
		private function updateNode(node:ArrowFlopNode, time:Number):void
		{
			node.spatial.rotation = Math.sin((node.flop.target.rotation + node.flop.offset) * node.flop.flops / 180 * Math.PI) * node.flop.floppage;
			if(node.spatial.rotation > node.flop.floppage / 2 && ! node.flop.flipped)
			{
				node.flop.flipped = true;
				if(node.flop.flopped)
					node.flop.flopped.dispatch();
			}
			if(node.spatial.rotation < -node.flop.floppage / 2 && node.flop.flipped)
			{
				node.flop.flipped = false;
			}
		}
	}
}