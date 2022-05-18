package game.scenes.deepDive1.maze.systems
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Spatial;
	
	import game.scenes.deepDive1.maze.Maze;
	import game.scenes.deepDive1.maze.components.FoodFish;
	import game.scenes.deepDive1.maze.nodes.MazeFishNode;
	
	public class MazeFishSystem extends ListIteratingSystem
	{
		public function MazeFishSystem($maze:Maze)
		{
			super(MazeFishNode, updateNode);
			_maze = $maze;
			_player = _maze.shellApi.player;
		}
		
		private function updateNode($node:MazeFishNode, $time:Number):void{
			for each(var fish:Entity in $node.mazeFish.mazeFish){
				if(FoodFish(fish.get(FoodFish)).state == "resting"){
					if(distanceFrom(fish, _player) < 200){
						_maze.pickupFish(fish);
					}
				}
			}
		}
		
		private function distanceFrom($entity1:Entity, $entity2:Entity):Number{
			var point1:Point = new Point(Spatial($entity1.get(Spatial)).x, Spatial($entity1.get(Spatial)).y);
			var point2:Point = new Point(Spatial($entity2.get(Spatial)).x, Spatial($entity2.get(Spatial)).y);
			
			return Point.distance(point1, point2);
		}
		
		private var _maze:Maze;
		private var _player:Entity;
	}
}