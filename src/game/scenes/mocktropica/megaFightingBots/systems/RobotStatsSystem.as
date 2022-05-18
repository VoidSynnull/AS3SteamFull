package game.scenes.mocktropica.megaFightingBots.systems
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.group.Group;
	
	import game.scenes.mocktropica.megaFightingBots.components.ArenaRobot;
	import game.scenes.mocktropica.megaFightingBots.nodes.ArenaNode;
	
	public class RobotStatsSystem extends ListIteratingSystem
	{
		/**
		 * DEPRECIATED SYSTEM - DO NOT USE
		 */
		public function RobotStatsSystem($container:DisplayObjectContainer, $group:Group)
		{
			_sceneGroup = $group;
			_container = $container;
			super(ArenaNode, updateNode);
		}
		
		protected function updateNode($node:ArenaNode, $time:Number):void{
			// update each robot in arena
			for each(var robotEntity:Entity in $node.arena.robots){
				var robot:ArenaRobot = robotEntity.get(ArenaRobot);
				
			}
		}
		
		protected var _container:DisplayObjectContainer;
		protected var _sceneGroup:Group;
	}
}