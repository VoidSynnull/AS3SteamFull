package game.scenes.deepDive2.shared.systems
{
	import ash.tools.ListIteratingSystem;
	
	import game.components.hit.Wall;
	import game.scenes.deepDive2.shared.nodes.BreakableNode;
	
	public class BreakableSystem extends ListIteratingSystem
	{
		public function BreakableSystem()
		{
			super(BreakableNode, updateNode);
		}
		
		private function updateNode(node:BreakableNode, time:Number):void
		{
			if(node.movieClipHit.isHit && !node.breakable.impact && node.breakable.strength > 0)
			{
				node.breakable.impact = true;
				node.breakable.wallHit.dispatch(node.entity);
				if(node.breakable.strength >= 1)
				{
					// reduce strength
					node.breakable.strength--;
					node.timeline.nextFrame();
					node.timeline.gotoAndStop(node.timeline.nextIndex);
					
					if(node.breakable.strength == 0)
					{
						if(node.wall)
						{
							node.entity.remove(Wall);
						}
					}
				}
			} 
			else if(!node.movieClipHit.isHit)
			{
				node.breakable.impact = false;
			}
		}
	}
}