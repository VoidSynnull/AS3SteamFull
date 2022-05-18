package game.scenes.mocktropica.megaFightingBots.components
{
	import com.greensock.TimelineMax;
	import com.greensock.TweenLite;
	import com.greensock.TweenMax;
	import com.greensock.easing.Expo;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Display;
	
	import game.scenes.mocktropica.megaFightingBots.MegaFightingBots;

	public class RobotStats extends Component
	{
		public function RobotStats($healthMC:MovieClip, $energyMC:MovieClip, $portraitMC:MovieClip, $robot:ArenaRobot, $robotDisplay:Display, $alertMC:MovieClip, $sceneGroup:MegaFightingBots, $robotEntity:Entity)
		{
			healthMC = $healthMC;
			energyMC = $energyMC;
			portraitMC = $portraitMC;
			_robot = $robot;
			_robotDisplay = $robotDisplay;
			_alertMC = $alertMC;
			_sceneGroup = $sceneGroup;
			_robotEntity = $robotEntity;
		}
		
		public function updateHealth($speed:Number = 1):void{
			// tween health bar to appropriate setting
			var p:Number = _robot.hitPoints / _robot.maxHitPoints;
			var pWidth:Number = healthMC.track.width * p;
			TweenLite.to(healthMC.fill, $speed, {width:pWidth});
			if(_robot.hitPoints <= 0.2*_robot.maxHitPoints){
				healthMC.warning.visible = true;
				healthMC.fill.play();
				if(_robot.playerRobot){
					_alertMC.play();
					if(!_sceneGroup.gettingClose){
						_sceneGroup.shellApi.triggerEvent("losing");
						_sceneGroup.gettingClose = true;
					}
				} else {
					
				}
			} else {
				healthMC.warning.visible = false;
				healthMC.fill.gotoAndStop(1);
			}
		}
		
		public function updateEnergy($speed:Number = 1):void{
			var p:Number = _robot.energyPoints / _robot.maxEnergyPoints;
			var pWidth:Number = energyMC.track.width * p;
			TweenLite.to(energyMC.fill, $speed, {width:pWidth});
			
			// check exhaustion
			if(_robot.energyPoints <= 0 && !_robot.energyExhausted){
				energyExhaustion();
			} else if(_robot.energyPoints >= _robot.maxEnergyPoints && _robot.energyExhausted){
				energyRecover();
			}
			
			// check warnings
			if(!_robot.energyExhausted){
				if(_robot.energyPoints <= 0.3*_robot.maxEnergyPoints){
					// display warning
					energyMC.warning.visible = true;
					energyMC.fill.play();
				} else {
					// hide warning
					energyMC.warning.visible = false;
					energyMC.fill.gotoAndStop(1);
				}
			}
		}
		
		public function rechargeEnergy($amount:Number = 0.25):void{
			if(_robot.energyPoints < _robot.maxEnergyPoints){
				_robot.energyPoints += $amount;
			}
			updateEnergy();
		}
		
		private function energyExhaustion():void{
			energyMC.fill.play(); // flash red
			_robot.energyExhausted = true;
			_robotDisplay.displayObject["sweat"].visible = true;
			
			// play sound
			if(_robot.playerRobot){
				RobotSounds(_robotEntity.get(RobotSounds)).exhaust();
			}
		}
		
		private function energyRecover():void{
			energyMC.fill.gotoAndStop(1);
			_robot.energyExhausted = false;
			_robotDisplay.displayObject["sweat"].visible = false;
			
			// stop sound
			if(_robot.playerRobot){
				RobotSounds(_robotEntity.get(RobotSounds)).exhaust(true);
			}
		}
		
		public function strikePortrait($reset:Boolean = false):void{
			if(!$reset){
				portraitMC.portrait.gotoAndStop(2);
			} else {
				portraitMC.portrait.gotoAndStop(1);
			}
		}
		
		public function winState():void{
			_robotDisplay.displayObject["sweat"].visible = false;
		}
		
		public function loseState():void{
			_robotDisplay.displayObject["sweat"].visible = false;
		}
		
		public var portraitMC:MovieClip;
		public var healthMC:MovieClip;
		public var energyMC:MovieClip;
		
		private var _timeline:TimelineMax;
		private var _robot:ArenaRobot;
		private var _robotDisplay:Display;
		private var _robotEntity:Entity;
		
		private var _alertMC:MovieClip;
		private var _sceneGroup:MegaFightingBots;
	}
}