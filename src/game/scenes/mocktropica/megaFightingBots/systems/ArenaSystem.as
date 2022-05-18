package game.scenes.mocktropica.megaFightingBots.systems
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import game.components.timeline.Timeline;
	import game.scenes.mocktropica.megaFightingBots.MegaFightingBots;
	import game.scenes.mocktropica.megaFightingBots.components.ArenaRobot;
	import game.scenes.mocktropica.megaFightingBots.components.RobotStats;
	import game.scenes.mocktropica.megaFightingBots.nodes.ArenaNode;
	
	import engine.components.Display;
	
	public class ArenaSystem extends ListIteratingSystem
	{
		public function ArenaSystem($container:DisplayObjectContainer, $group:MegaFightingBots)
		{
			_sceneGroup = $group;
			_container = $container;
			super(ArenaNode, updateNode);
		}
		
		protected function updateNode($node:ArenaNode, $time:Number):void{
			// init once
			if(!_init){
				_node = $node;
				init();
			}
			// read game state from Arena
			var robotEntity:Entity;
			switch($node.arena.gameState){
				case 0:
					// freeze robots into start coordinates
					for each(robotEntity in $node.arena.robots){
						ArenaRobot(robotEntity.get(ArenaRobot)).freeze = true;
						ArenaRobot(robotEntity.get(ArenaRobot)).moveCoord = ArenaRobot(robotEntity.get(ArenaRobot)).startPoint;
					}
					break;
				case 1:
					// game intro
					if(_starting == false){
						$node.arena.exciteCrowd(true);
						$node.arena.round++;
						_starting = true;
						Display($node.arena.vs.get(Display)).displayObject["round"].gotoAndStop($node.arena.round);
						if($node.arena.round == 1){
							Timeline($node.arena.vs.get(Timeline)).gotoAndPlay(2);
						} else {
							Timeline($node.arena.vs.get(Timeline)).gotoAndPlay("round");
						}
						_sceneGroup.setVS();
						for each(robotEntity in $node.arena.robots){
							RobotStats(robotEntity.get(RobotStats)).strikePortrait(true);
							RobotStats(robotEntity.get(RobotStats)).updateHealth(3);
							RobotStats(robotEntity.get(RobotStats)).updateEnergy(3);
						}
					}
					
					break;
				case 2:
					// game is playing, release robots
					_starting = false;
					for each(robotEntity in $node.arena.robots){
						ArenaRobot(robotEntity.get(ArenaRobot)).freeze = false;
					}
					break;
				case 3:
					// knock out has occured, freeze robots and excite crowd
					for each(robotEntity in $node.arena.robots){
						ArenaRobot(robotEntity.get(ArenaRobot)).freeze = true;
					}
					_sceneGroup.setKO();
					$node.arena.exciteCrowd(true);
					break;
				case 4:
					
					break;
			}
		}
		
		private function init():void{
			Timeline(_node.arena.vs.get(Timeline)).handleLabel("getReady", getReady, false);
			Timeline(_node.arena.vs.get(Timeline)).handleLabel("go", startGame, false);
			_init = true;
		}
		
		private function getReady():void{
			_node.arena.cameraFlashes.visible = false;
			switch(_node.arena.round){
				case 1:
					_sceneGroup.shellApi.triggerEvent("round1");
					break;
				case 2:
					_sceneGroup.shellApi.triggerEvent("round2");
					break;
				case 3:
					_sceneGroup.shellApi.triggerEvent("finalRound");
					break;
			}
		}
		
		private function startGame():void{
			trace("START GAME");
			_sceneGroup.shellApi.triggerEvent("go");
			_node.arena.gameState = 2;
		}
		
		private var _node:ArenaNode;
		private var _init:Boolean = false;
		private var _starting:Boolean = false;
		
		protected var _container:DisplayObjectContainer;
		protected var _sceneGroup:MegaFightingBots;
	}
}