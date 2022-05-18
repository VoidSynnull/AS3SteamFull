package game.scenes.mocktropica.megaFightingBots.components
{
	import engine.components.Audio;
	import ash.core.Component;
	import engine.managers.SoundManager;
	
	import game.data.TimedEvent;
	import game.data.sound.SoundData;
	import game.scenes.mocktropica.megaFightingBots.MegaFightingBots;
	
	
	public class RobotSounds extends Component
	{
		public function RobotSounds($audio:Audio, $sceneGroup:MegaFightingBots)
		{
			super();
			audio = $audio;
			_sceneGroup = $sceneGroup;

			walkSoundData = new SoundData();
			walkSoundData.asset = SoundManager.EFFECTS_PATH + "robotWalkSound_loop.mp3";
			walkSoundData.loop = true;
			walkSoundData.allowOverlap = true;
			
			attackSoundData = new SoundData();
			attackSoundData.asset = SoundManager.EFFECTS_PATH + "crushed_whoosh_01.mp3";
			attackSoundData.loop = false;
			attackSoundData.allowOverlap = true;
			
			hitSoundData = new SoundData();
			hitSoundData.asset = SoundManager.EFFECTS_PATH + "robot_to_robot_impact_01.mp3";
			hitSoundData.allowOverlap = true;
			
			hitSoundData2 = new SoundData();
			hitSoundData2.asset = SoundManager.EFFECTS_PATH + "robot_to_robot_impact_02.mp3";
			hitSoundData2.allowOverlap = true;
			
			hitSoundData3 = new SoundData();
			hitSoundData3.asset = SoundManager.EFFECTS_PATH + "robot_to_robot_impact_03.mp3";
			hitSoundData3.allowOverlap = true;
			
			hitSoundData4 = new SoundData();
			hitSoundData4.asset = SoundManager.EFFECTS_PATH + "robot_to_robot_impact_04.mp3";
			hitSoundData4.allowOverlap = true;
			
			hitSoundData5 = new SoundData();
			hitSoundData5.asset = SoundManager.EFFECTS_PATH + "robot_to_robot_impact_05.mp3";
			hitSoundData5.allowOverlap = true;
			
			impactSoundData = new SoundData();
			impactSoundData.asset = SoundManager.EFFECTS_PATH + "wall_impact_01.mp3";
			impactSoundData.allowOverlap = true;
			
			impactSoundData2 = new SoundData();
			impactSoundData2.asset = SoundManager.EFFECTS_PATH + "wall_impact_02.mp3";
			impactSoundData2.allowOverlap = true;
			
			exhaustSoundData = new SoundData();
			exhaustSoundData.asset = SoundManager.EFFECTS_PATH + "over_exerted_01_L.mp3";
			exhaustSoundData.allowOverlap = true;
			exhaustSoundData.loop = true;
			
			breakSoundData = new SoundData();
			breakSoundData.asset = SoundManager.EFFECTS_PATH + "finishing_blow_01.mp3";
			breakSoundData.allowOverlap = true;
			
			crowdSoundData = new SoundData();
			crowdSoundData.asset = SoundManager.EFFECTS_PATH + "oh_01.mp3";
			crowdSoundData.allowOverlap = false;
			
			crowdSoundData2 = new SoundData();
			crowdSoundData2.asset = SoundManager.EFFECTS_PATH + "crowd_cheer_01.mp3";
			crowdSoundData2.allowOverlap = false;
			
			crowdSoundData3 = new SoundData();
			crowdSoundData3.asset = SoundManager.EFFECTS_PATH + "crowd_cheer_02.mp3";
			crowdSoundData3.allowOverlap = false;
			
			coinUpSound= new SoundData();
			coinUpSound.asset = SoundManager.EFFECTS_PATH + "coin_up_v2_01.mp3";
			coinUpSound.allowOverlap = false;
		}
		
		public function walk($cancel:Boolean = false):void{
			if(!$cancel && !walking){
				// loop sound
				walking = true;
				//audio.playFromSoundData(walkSoundData);
			} else if($cancel){
				// stop loop
				//audio.stop(walkSoundData.asset);
				walking = false;
			}
		}
		
		public function exhaust($cancel:Boolean = false):void{
			if(!$cancel){
				audio.playFromSoundData(exhaustSoundData);
			} else {
				audio.stop(exhaustSoundData.asset);
			}
		}
		
		public function breakDown():void{
			stopAll(); // stop all other sounds
			audio.playFromSoundData(breakSoundData);
		}
		
		public function attack():void{
			audio.playFromSoundData(attackSoundData);
		}
		
		public function hit():void{
			switch(Math.round(Math.random()*4)){
				case 0:
					audio.playFromSoundData(hitSoundData);
					break;
				case 1:
					audio.playFromSoundData(hitSoundData2);
					break;
				case 2:
					audio.playFromSoundData(hitSoundData3);
					break;
				case 3:
					audio.playFromSoundData(hitSoundData4);
					break;
				case 4:
					audio.playFromSoundData(hitSoundData5);
					break;
				default:
					audio.playFromSoundData(hitSoundData);
					break;
			}
		}
		
		public function impact():void{
			switch(Math.round(Math.random()*1)){
				case 0:
					audio.playFromSoundData(impactSoundData);
					break;
				case 1:
					audio.playFromSoundData(impactSoundData2);
					break;
				default:
					audio.playFromSoundData(impactSoundData);
					break;
			}
			crowdReact();
		}
		
		public function crowdReact():void{
			switch(Math.round(Math.random()*2)){
				case 0:
					audio.playFromSoundData(crowdSoundData);
					break;
				case 1:
					audio.playFromSoundData(crowdSoundData2);
					break;
				case 2:
					audio.playFromSoundData(crowdSoundData2); // set on purpose
					break;
				default:
					audio.playFromSoundData(crowdSoundData);
					break;
			}
		}
		
		public function coinUp():void{
			audio.playFromSoundData(coinUpSound);
		}
		
		public function stopAll():void{
			audio.stopAll();
		}
		
		public var walking:Boolean = false;
		
		public var audio:Audio;
		
		public var walkSoundData:SoundData;
		
		public var attackSoundData:SoundData;
		
		public var hitSoundData:SoundData;
		public var hitSoundData2:SoundData;
		public var hitSoundData3:SoundData;
		public var hitSoundData4:SoundData;
		public var hitSoundData5:SoundData;
		
		public var impactSoundData:SoundData;
		public var impactSoundData2:SoundData;
		
		public var exhaustSoundData:SoundData;
		
		public var crowdSoundData:SoundData;
		public var crowdSoundData2:SoundData;
		public var crowdSoundData3:SoundData;
		
		public var stepTimerEvent:TimedEvent;
		private var _sceneGroup:MegaFightingBots;
		private var breakSoundData:SoundData;
		
		[Inject]
		public var _soundManager:SoundManager;
		private var coinUpSound:SoundData;
	}
}