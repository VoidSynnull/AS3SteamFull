package game.scenes.mocktropica.megaFightingBots.systems
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.util.Pathfinding;
	
	import game.scenes.mocktropica.megaFightingBots.components.ArenaRobot;
	import game.scenes.mocktropica.megaFightingBots.nodes.ArenaNode;
	
	public class EnemyAISystem extends ListIteratingSystem
	{
		public function EnemyAISystem($container:DisplayObjectContainer, $group:Group)
		{
			_sceneGroup = $group;
			_container = $container;
			super(ArenaNode, updateNode);
		}
		
		protected function updateNode($node:ArenaNode, $time:Number):void{
			for each(var robotEntity:Entity in $node.arena.robots){
				if(ArenaRobot(robotEntity.get(ArenaRobot)).playerRobot != true && !ArenaRobot(robotEntity.get(ArenaRobot)).freeze){
					var robot:ArenaRobot = robotEntity.get(ArenaRobot);
					var display:MovieClip = Display(robotEntity.get(Display)).displayObject as MovieClip;
					var spatial:Spatial = robotEntity.get(Spatial);
					var pathToPoint:Point;
					
					if(robot.atDestination == true){
						
						if(robot.aggression > Math.random()){
							// move to player
							pathToPoint = ArenaRobot($node.arena.playerRobot.get(ArenaRobot)).moveCoord;
						} else {
							// move randomly
							var validSquares:Vector.<Point> = new Vector.<Point>;
							for(var c:int = 0; c < $node.arena.grid.length; c++){
								for(var d:int = 0; d < $node.arena.grid[c].length; d++){
									if($node.arena.grid[c][d] != 0){
										validSquares.push(new Point(d,c));
									}
								}
							}
							
							
							// get random square
							var rand:int = Math.random()*validSquares.length;
							pathToPoint = validSquares[rand];
						}
						
						// path to new square
						var pathfinder:Pathfinding = new Pathfinding();
						//trace("moveCoord:"+robot.moveCoord.x+":"+robot.moveCoord.y);
						//trace("pathToPoint:"+pathToPoint.x+":"+pathToPoint.y);
						robot.path = pathfinder.findPathInternal($node.arena.grid, robot.moveCoord.y, robot.moveCoord.x, pathToPoint.y, pathToPoint.x);
						robot.path.pop();
						
					} else {
						if(robot.charging != true && playerInChargePath(robot, $node) && !robot.energyExhausted){
							robot.chargeDir = robot.currentFaceDir;
						}
					}
				}
			}
		}
		
		private function playerInChargePath($robot:ArenaRobot, $node:ArenaNode):Boolean{
			// create 2 squares of charge path
			var square1:Point;
			var square2:Point;
			
			switch($robot.currentFaceDir){
				case "right":
					square1 = new Point($robot.hitCoord.x + 1, $robot.hitCoord.y);
					square2 = new Point($robot.hitCoord.x + 2, $robot.hitCoord.y);
					break;
				case "left":
					square1 = new Point($robot.hitCoord.x - 1, $robot.hitCoord.y);
					square2 = new Point($robot.hitCoord.x - 2, $robot.hitCoord.y);
					break;
				case "down":
					square1 = new Point($robot.hitCoord.x, $robot.hitCoord.y + 1);
					square2 = new Point($robot.hitCoord.x, $robot.hitCoord.y + 2);
					break;
				case "up":
					square1 = new Point($robot.hitCoord.x, $robot.hitCoord.y - 1);
					square2 = new Point($robot.hitCoord.x, $robot.hitCoord.y - 2);
					break;
			}
			
			// check squares for player robot
			if(ArenaRobot($node.arena.playerRobot.get(ArenaRobot)).hitCoord.equals(square1) || ArenaRobot($node.arena.playerRobot.get(ArenaRobot)).hitCoord.equals(square2)){
				return true;
			}
			
			return false;
		}
		
		protected var _container:DisplayObjectContainer;
		protected var _sceneGroup:Group;
	}
}