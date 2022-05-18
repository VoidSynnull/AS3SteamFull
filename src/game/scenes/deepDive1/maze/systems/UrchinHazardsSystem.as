package game.scenes.deepDive1.maze.systems
{
	import ash.tools.ListIteratingSystem;
	
	import game.components.entity.collider.HazardCollider;
	import game.scenes.deepDive1.maze.Maze;
	import game.scenes.deepDive1.maze.nodes.UrchinHazardsNode;
	
	public class UrchinHazardsSystem extends ListIteratingSystem
	{
		public function UrchinHazardsSystem($maze:Maze)
		{
			_maze = $maze;
			super(UrchinHazardsNode, updateNode);
		}
		
		private function updateNode($node:UrchinHazardsNode, $time:Number):void{
			if(HazardCollider($node.urchinHazards.player.get(HazardCollider)).isHit && !_recovering){
				_maze.playMessage("bumpUrchin");
				_maze.loseAFish();
				_maze.shellApi.triggerEvent("urchin");
				_recovering = true;
			} else if(!HazardCollider($node.urchinHazards.player.get(HazardCollider)).isHit && _recovering){
				_recovering = false;
				trace("RECOVERED!");
				// PATCH - force restore controls
				_maze.restoreControls();
			}
		}
		
		private var _maze:Maze;
		private var _recovering:Boolean = false;
	}
}