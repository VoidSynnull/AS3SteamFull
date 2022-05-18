package game.scenes.mocktropica.megaFightingBots.components
{
	import flash.display.MovieClip;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Display;
	
	import game.components.timeline.Timeline;
	import game.scenes.mocktropica.megaFightingBots.MegaFightingBots;
	import game.scenes.mocktropica.megaFightingBots.particles.SparkParticles;
	
	public class Arena extends Component
	{
		
		public function Arena($gridZero:Point, $cameraFlashes:MovieClip, $cellSize:Number = 62.00){
			cellSize = $cellSize;
			gridZero = $gridZero;
			cameraFlashes = $cameraFlashes;
		}
		
		public function exciteCrowd($noTimer:Boolean = false):void{
			cameraFlashes.visible = true;
			if(!$noTimer){
				_timer = new Timer(300, 1);
				_timer.addEventListener(TimerEvent.TIMER_COMPLETE, calmCrowd);
				_timer.start();
			}
		}
		
		private function calmCrowd($event:TimerEvent):void{
			_timer.removeEventListener(TimerEvent.TIMER_COMPLETE, calmCrowd);
			cameraFlashes.visible = false;
		}
		
		public function playRobotDialog():void{
			for each(var robotEntity:Entity in robots){
				RobotStats(robotEntity.get(RobotStats)).updateHealth(3);
				RobotStats(robotEntity.get(RobotStats)).updateEnergy(3);
			}
			exciteCrowd();
			var timeLine:Timeline = robotDialogs.get(Timeline);
			timeLine.gotoAndPlay("stage"+stage);
			timeLine.handleLabel("stage"+stage+"end", startGame, true);
		}
		
		private function startGame():void{
			megaFightingBots.shellApi.triggerEvent("cheer");
			gameState = 1;
		}
		
		// define 2D array to serve as grid
		public var grid:Array = [
			[0,0,0,0,0,0,0,0,0,0,0,0],
			[0,1,1,1,1,1,1,1,1,1,1,0],
			[0,1,0,0,0,1,1,0,0,0,1,0],
			[0,1,0,0,0,1,1,0,0,0,1,0],
			[0,1,0,0,0,1,1,0,0,0,1,0],
			[0,1,1,1,1,1,1,1,1,1,1,0],
			[0,0,0,0,0,0,0,0,0,0,0,0]
		];
		
		// spacing of grid tiles
		public var cellSize:Number;;
		
		// zero point of grid
		public var gridZero:Point;
		
		// robots present on grid
		public var robots:Vector.<Entity> = new Vector.<Entity>;
		
		/**
		 * Game States
		 * 0 - in menu screen
		 * 1 - arena intro
		 * 2 - game on
		 * 3 - game finished victory/defeat
		 */
		public var gameState:int = 0;
		
		
		// player robot
		public var playerRobot:Entity;
		
		// enemy robot
		public var cpuRobot:Entity;
		
		public var origPoint:Point;
		
		public var sparkEmitter:SparkParticles;
		public var sparkEntity:Entity;
		
		public var robotDialogs:Entity;
		
		public var cameraFlashes:MovieClip;
		
		public var mainMenu:Entity;
		public var vs:Entity;
		public var ko:Entity;
		
		public var stage:int = 1; // which bot the player is fighting (1 is default - safety bot)
		
		public var round:int = 0;
		
		private var _timer:Timer;
		
		public var megaFightingBots:MegaFightingBots;
		
		// game interface
		public var gameInterface:MovieClip;
		
		
	}
}