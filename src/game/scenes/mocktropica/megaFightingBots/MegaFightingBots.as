package game.scenes.mocktropica.megaFightingBots
{
	import com.greensock.TweenLite;
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioSequence;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	import engine.systems.MotionSystem;
	import engine.util.Pathfinding;
	
	import game.components.timeline.Timeline;
	import game.components.ui.Cursor;
	import game.creators.entity.EmitterCreator;
	import game.data.scene.SceneParser;
	import game.data.sound.SoundType;
	import game.data.ui.ToolTipType;
	import game.scene.SceneSound;
	import game.scene.template.AudioGroup;
	import game.scene.template.CameraGroup;
	import game.scene.template.GameScene;
	import game.scenes.mocktropica.MocktropicaEvents;
	import game.scenes.mocktropica.classroom.Classroom;
	import game.scenes.mocktropica.hangar.Hangar;
	import game.scenes.mocktropica.megaFightingBots.components.Arena;
	import game.scenes.mocktropica.megaFightingBots.components.ArenaControl;
	import game.scenes.mocktropica.megaFightingBots.components.ArenaRobot;
	import game.scenes.mocktropica.megaFightingBots.components.RobotSounds;
	import game.scenes.mocktropica.megaFightingBots.components.RobotStats;
	import game.scenes.mocktropica.megaFightingBots.particles.DustParticles;
	import game.scenes.mocktropica.megaFightingBots.particles.SparkParticles;
	import game.scenes.mocktropica.megaFightingBots.systems.ArenaSystem;
	import game.scenes.mocktropica.megaFightingBots.systems.EnemyAISystem;
	import game.scenes.mocktropica.megaFightingBots.systems.RobotSystem;
	import game.systems.SystemPriorities;
	import game.systems.input.InteractionSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.util.AudioUtils;
	import game.util.TimelineUtils;
	
	
	public class MegaFightingBots extends Scene
	{
		public function MegaFightingBots()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			// check override scene (to hide close button) - coming from megaFightingBots.com
			if (shellApi.sceneManager.gameData.overrideScene == "game.scenes.mocktropica.megaFightingBots.MegaFightingBots") {
				_overrideScene = true;				
			}
			trace("^^^^^^^^^^^^^^^^^^^^^^ Easier version enabled!");
			trace("^^^^^^^^^^^^^^^^^^^^^^ scene override: " + shellApi.sceneManager.gameData.overrideScene);
			
			super.groupPrefix = "scenes/mocktropica/megaFightingBots/";
			
			super.init(container);
			
			load();
		}
				
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			//super.load();
			super.shellApi.fileLoadComplete.addOnce(loadAssets);
			super.loadFiles([GameScene.SCENE_FILE_NAME,GameScene.SOUNDS_FILE_NAME]);
		}
		
		protected function loadAssets():void
		{
			var parser:SceneParser = new SceneParser();
			var sceneXml:XML = super.getData(GameScene.SCENE_FILE_NAME);
			
			super.sceneData = parser.parse(sceneXml);			
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(super.sceneData.assets);
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			addBaseSystems();
			addGameSystems();
			
			var cameraGroup:CameraGroup = new CameraGroup();
			
			cameraGroup.setupScene(this, 1);
			
			// keep a reference to the hit layer so we can refer to it later when adding other entities.
			_hitContainer = Display(super.getEntityById("interactive").get(Display)).displayObject;
			
			// setup camera target
			_target = new Entity();
			_target.add(new Display(_hitContainer["target"]));
			_target.add(new Spatial());
			
			CameraGroup(super.getGroupById("cameraGroup")).target = _target.get(Spatial);
			super.addEntity(_target);
			
			//Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.TARGET;  // change default cursor
			
			_previousScene = super.shellApi.sceneManager.previousScene;
			
			// if classroom, switch to classroom version
			if(super.shellApi.sceneManager.previousScene == "game.scenes.mocktropica.classroom::Classroom"){
				
				// show close button
				_closeButton = new Entity();
				_closeButton.add(new Display(_hitContainer["closeButton"]));
				_closeButton.add(new Spatial());
				var closeButtonInt:Interaction = InteractionCreator.addToEntity(_closeButton, [InteractionCreator.DOWN]);
				closeButtonInt.down.addOnce(onClose);
				
				super.addEntity(_closeButton);
				
				_hitContainer["frame"].gotoAndStop(2);
				
				// if MFB defeated, play in classroom.
				var mocktropicaEvents:MocktropicaEvents = new MocktropicaEvents();
				if(super.shellApi.checkEvent(mocktropicaEvents.DEFEATED_MFB)){
					_bonusQuest = true;
				}
				
				//} else if(super.shellApi.sceneManager.previousScene == "game.scenes.mocktropica.hangar:Hangar" && super.shellApi.checkEvent("started_bonus_quest")){
			} else if(super.shellApi.sceneManager.previousScene == "game.scenes.mocktropica.hangar::Hangar"){
				//trace("CHEAT MODE ON!");
				
				
				_closeButton = new Entity();
				_closeButton.add(new Display(_hitContainer["closeButton"]));
				_closeButton.add(new Spatial());
				var closeButtonInt2:Interaction = InteractionCreator.addToEntity(_closeButton, [InteractionCreator.DOWN]);
				closeButtonInt2.down.addOnce(onClose);
				
				super.addEntity(_closeButton);
				
				//_hitContainer["frame"].gotoAndStop(2);
				
				_bonusQuest = true;
			} else {
				_hitContainer["closeButton"].visible = false;
			}
			
			// create startMenu 
			_startMenu = new Entity();
			_startMenu.add(new Display(_hitContainer["startMenu"]));
			_startMenu.add(new Spatial());
			var startMenuInt:Interaction = InteractionCreator.addToEntity(_startMenu, [InteractionCreator.DOWN]);
			startMenuInt.down.addOnce(onStartMenu);
			
			super.addEntity(_startMenu);
			
			_megaCoinBar = new Entity();
			_megaCoinBar.add(new Display(_hitContainer["megaCoinBar"]));
			_megaCoinBar.add(new Spatial());
			var megaCoinInt:Interaction = InteractionCreator.addToEntity(_megaCoinBar, [InteractionCreator.DOWN]);
			megaCoinInt.down.add(onMegaCoin);
			
			if(_bonusQuest){
				MovieClip(Display(_megaCoinBar.get(Display)).displayObject).gotoAndStop(2);
			}
			
			super.addEntity(_megaCoinBar);
			
			_instructions = new Entity();
			_instructions.add(new Display(_hitContainer["instructionsScreen"]));
			_instructions.add(new Spatial());
			var instructionsInt:Interaction = InteractionCreator.addToEntity(_instructions, [InteractionCreator.DOWN]);
			instructionsInt.down.addOnce(onInstructions);
			
			super.addEntity(_instructions);
			
			_ladder = new Entity();
			_ladder.add(new Display(_hitContainer["ladderScreen"]));
			_ladder.add(new Spatial());
			var ladderInt:Interaction = InteractionCreator.addToEntity(_ladder, [InteractionCreator.DOWN]);
			ladderInt.down.addOnce(onLadder);
			
			super.addEntity(_ladder);
			
			// create winLose screen
			_winLose = new Entity();
			_winLose.add(new Display(_hitContainer["winLoseScreen"]));
			_winLose.add(new Spatial());
			Display(_winLose.get(Display)).visible = false;
			
			super.addEntity(_winLose);
			
			// create loseMsg screen
			_loseMsg = new Entity();
			_loseMsg.add(new Display(_hitContainer["loseMSG"]));
			_loseMsg.add(new Spatial());
			Display(_loseMsg.get(Display)).visible = false;
			var loseMsgInt:Interaction = InteractionCreator.addToEntity(_loseMsg, [InteractionCreator.DOWN]);
			loseMsgInt.down.addOnce(onLoseMsg);
			
			super.addEntity(_loseMsg);
			
			_hitContainer["cameraFlashes"].visible = false;
			_hitContainer["cameraFlashes"].mouseEnabled = false;
			_hitContainer["cameraFlashes"].mouseChildren = false;
			
			// create vs screen
			_vs = TimelineUtils.convertClip(_hitContainer["vs"], this);
			_vs.add(new Display(_hitContainer["vs"]));
			_vs.add(new Spatial());
			_vs.add(new Id("vsScreen"));
			
			_hitContainer["vs"].mouseEnabled = false;
			_hitContainer["vs"].mouseChildren = false;
			
			// create ko screen
			_ko = TimelineUtils.convertClip(_hitContainer["ko"], this);
			_ko.add(new Display(_hitContainer["ko"]));
			_ko.add(new Spatial());
			_ko.add(new Id("koScreen"));
			
			_hitContainer["ko"].mouseEnabled = false;
			_hitContainer["ko"].mouseChildren = false;
			
			// create save screen - countdown (buy megacoins)
			//_save = TimelineUtils.convertAllClips(_hitContainer["save"], null, this);
			_save = TimelineUtils.convertClip(_hitContainer["save"], this);
			_save.add(new Display(_hitContainer["save"]));
			_save.add(new Spatial());
			_save.add(new Id("saveScreen"));
			
			_hitContainer["save"].mouseEnabled = false;
			_hitContainer["save"].mouseChildren = false;
			
			_coinPopup = new Entity();
			_coinPopup.add(new Display(_hitContainer["coinPopup"]));
			_coinPopup.add(new Spatial());
			_coinPopup.add(new Id("coinPopupScreen"));
			Display(_coinPopup.get(Display)).visible = false;
			
			_hitContainer["coinPopup"].mouseEnabled = false;
			_hitContainer["coinPopup"].mouseChildren = false;
			
			super.addEntity(_coinPopup);
			
			_coinUp = TimelineUtils.convertClip(_hitContainer["coinUp"], this);
			_coinUp.add(new Display(_hitContainer["coinUp"]));
			_coinUp.add(new Spatial());
			//_coinUp.add(new id("coinUpScreen"));
			
			_hitContainer["coinUp"].mouseEnabled = false;
			_hitContainer["coinUp"].mouseChildren = false;
			
			_robotDialogs = TimelineUtils.convertClip(_hitContainer["gameInterface"]["dialogs"], this);
			_robotDialogs.add(new Display(_hitContainer["gameInterface"]["dialogs"]));
			_robotDialogs.add(new Spatial());
			
			_arena = new Entity();
			_arena.add(new Id("arena"));
			_arena.add(new Display(_hitContainer["grid"]));
			_arena.add(new Spatial());
			_arena.add(new Arena(new Point(_hitContainer["grid"].x, _hitContainer["grid"].y), _hitContainer["cameraFlashes"]));
			_arena.add(new ArenaControl(_hitContainer["gridTarg"]));
			_arenaInt = InteractionCreator.addToEntity(_arena, [InteractionCreator.DOWN]);
			_arenaInt.down.add(onArena);
			
			Arena(_arena.get(Arena)).megaFightingBots = this;
			Arena(_arena.get(Arena)).mainMenu = _startMenu;
			Arena(_arena.get(Arena)).vs = _vs;
			Arena(_arena.get(Arena)).ko = _ko;
			Arena(_arena.get(Arena)).robotDialogs = _robotDialogs;
			
			_hitContainer["gridTarg"].mouseEnabled = false;
			_hitContainer["gridTarg"].mouseChildren = false;
			_hitContainer["gridTarg"].visible = false;
			
			super.addEntity(_arena);
			
			// redalert mc - when danger is imminent
			_hitContainer["alertMC"].mouseEnabled = false;
			_hitContainer["alertMC"].mouseChildren = false;
			
			// create playerBot
			_playerBot = new Entity();
			_playerBot.add(new Display(_hitContainer["playerBot"]));
			_playerBot.add(new Spatial());
			_playerBot.add(new Audio());
			_playerBot.add(new RobotSounds(_playerBot.get(Audio), this));
			_playerBot.add(new ArenaRobot(new Point(1,1), 120, 150));
			_playerBot.add(new RobotStats(_hitContainer["gameInterface"].meters.p1health, _hitContainer["gameInterface"].meters.p1energy, _hitContainer["gameInterface"].p1Portrait, _playerBot.get(ArenaRobot), _playerBot.get(Display), _hitContainer["alertMC"], this, _playerBot));
			_hitContainer["playerBot"].mouseEnabled = false;
			_hitContainer["playerBot"].mouseChildren = false;
			_hitContainer["playerBot"].sweat.visible = false;
			
			// create facing entities
			ArenaRobot(_playerBot.get(ArenaRobot)).frontEntity = TimelineUtils.convertClip(Display(_playerBot.get(Display)).displayObject["botMC_front"], this);
			ArenaRobot(_playerBot.get(ArenaRobot)).frontEntity.add(new Display(Display(_playerBot.get(Display)).displayObject["botMC_front"]));
			ArenaRobot(_playerBot.get(ArenaRobot)).frontEntity.add(new Spatial());
			ArenaRobot(_playerBot.get(ArenaRobot)).frontEntity.add(new Id("playerFront"));
			ArenaRobot(_playerBot.get(ArenaRobot)).backEntity = TimelineUtils.convertClip(Display(_playerBot.get(Display)).displayObject["botMC_back"], this);
			ArenaRobot(_playerBot.get(ArenaRobot)).backEntity.add(new Display(Display(_playerBot.get(Display)).displayObject["botMC_back"]));
			ArenaRobot(_playerBot.get(ArenaRobot)).backEntity.add(new Spatial());
			ArenaRobot(_playerBot.get(ArenaRobot)).backEntity.add(new Id("playerBack"));
			ArenaRobot(_playerBot.get(ArenaRobot)).leftEntity = TimelineUtils.convertClip(Display(_playerBot.get(Display)).displayObject["botMC_left"], this);
			ArenaRobot(_playerBot.get(ArenaRobot)).leftEntity.add(new Display(Display(_playerBot.get(Display)).displayObject["botMC_left"]));
			ArenaRobot(_playerBot.get(ArenaRobot)).leftEntity.add(new Spatial());
			ArenaRobot(_playerBot.get(ArenaRobot)).leftEntity.add(new Id("playerLeft"));
			ArenaRobot(_playerBot.get(ArenaRobot)).rightEntity = TimelineUtils.convertClip(Display(_playerBot.get(Display)).displayObject["botMC_right"], this);
			ArenaRobot(_playerBot.get(ArenaRobot)).rightEntity.add(new Display(Display(_playerBot.get(Display)).displayObject["botMC_right"]));
			ArenaRobot(_playerBot.get(ArenaRobot)).rightEntity.add(new Spatial());
			ArenaRobot(_playerBot.get(ArenaRobot)).rightEntity.add(new Id("playerRight"));
			
			ArenaRobot(_playerBot.get(ArenaRobot)).playerRobot = true; // set player robot
			ArenaRobot(_playerBot.get(ArenaRobot)).dustEmitter = new DustParticles();
			ArenaRobot(_playerBot.get(ArenaRobot)).dustEmitter.init();
			ArenaRobot(_playerBot.get(ArenaRobot)).dustEntity = EmitterCreator.create(this, _hitContainer, ArenaRobot(_playerBot.get(ArenaRobot)).dustEmitter, Spatial(_playerBot.get(Spatial)).x, Spatial(_playerBot.get(Spatial)).y );
			//ArenaRobot(_playerBot.get(ArenaRobot)).dustEmitter.dustOn();
			
			Arena(_arena.get(Arena)).playerRobot = _playerBot;
			
			var dustDisplay1:DisplayObject = Display(ArenaRobot(_playerBot.get(ArenaRobot)).dustEntity.get(Display)).displayObject;
			
			_hitContainer.swapChildren(dustDisplay1, _hitContainer["playerBot"]);
			
			super.addEntity(_playerBot);
			
			// create enemyBot
			_enemyBot = new Entity();
			_enemyBot.add(new Display(_hitContainer["enemyBot"]));
			_enemyBot.add(new Spatial());
			_enemyBot.add(new Audio());
			_enemyBot.add(new RobotSounds(_enemyBot.get(Audio), this));
			_enemyBot.add(new ArenaRobot(new Point(10,5)));
			_enemyBot.add(new RobotStats(_hitContainer["gameInterface"].meters.p2health, _hitContainer["gameInterface"].meters.p2energy, _hitContainer["gameInterface"].p2Portrait, _enemyBot.get(ArenaRobot), _enemyBot.get(Display), _hitContainer["alertMC"], this, _enemyBot));
			
			_hitContainer["enemyBot"].mouseEnabled = false;
			_hitContainer["enemyBot"].mouseChildren = false;
			_hitContainer["enemyBot"].sweat.visible = false;
			
			ArenaRobot(_enemyBot.get(ArenaRobot)).newRobotStage(1);
			
			// create facing entities
			ArenaRobot(_enemyBot.get(ArenaRobot)).frontEntity = TimelineUtils.convertClip(Display(_enemyBot.get(Display)).displayObject["botMC_front"] as MovieClip, this);
			ArenaRobot(_enemyBot.get(ArenaRobot)).frontEntity.add(new Display(Display(_enemyBot.get(Display)).displayObject["botMC_front"]));
			ArenaRobot(_enemyBot.get(ArenaRobot)).frontEntity.add(new Spatial());
			ArenaRobot(_enemyBot.get(ArenaRobot)).backEntity = TimelineUtils.convertClip(Display(_enemyBot.get(Display)).displayObject["botMC_back"] as MovieClip, this);
			ArenaRobot(_enemyBot.get(ArenaRobot)).backEntity.add(new Display(Display(_enemyBot.get(Display)).displayObject["botMC_back"] as MovieClip));
			ArenaRobot(_enemyBot.get(ArenaRobot)).backEntity.add(new Spatial());
			ArenaRobot(_enemyBot.get(ArenaRobot)).leftEntity = TimelineUtils.convertClip(Display(_enemyBot.get(Display)).displayObject["botMC_left"] as MovieClip, this);
			ArenaRobot(_enemyBot.get(ArenaRobot)).leftEntity.add(new Display(Display(_enemyBot.get(Display)).displayObject["botMC_left"]));
			ArenaRobot(_enemyBot.get(ArenaRobot)).leftEntity.add(new Spatial());
			ArenaRobot(_enemyBot.get(ArenaRobot)).rightEntity = TimelineUtils.convertClip(Display(_enemyBot.get(Display)).displayObject["botMC_right"] as MovieClip, this);
			ArenaRobot(_enemyBot.get(ArenaRobot)).rightEntity.add(new Display(Display(_enemyBot.get(Display)).displayObject["botMC_right"]));
			ArenaRobot(_enemyBot.get(ArenaRobot)).rightEntity.add(new Spatial());
			
			ArenaRobot(_enemyBot.get(ArenaRobot)).dustEmitter = new DustParticles();
			ArenaRobot(_enemyBot.get(ArenaRobot)).dustEmitter.init();
			ArenaRobot(_enemyBot.get(ArenaRobot)).dustEntity = EmitterCreator.create(this, _hitContainer, ArenaRobot(_enemyBot.get(ArenaRobot)).dustEmitter, Spatial(_enemyBot.get(Spatial)).x, Spatial(_enemyBot.get(Spatial)).y );
			
			var dustDisplay2:DisplayObject = Display(ArenaRobot(_enemyBot.get(ArenaRobot)).dustEntity.get(Display)).displayObject;
			
			_hitContainer.swapChildren(dustDisplay2, _hitContainer["enemyBot"]);
			
			super.addEntity(_enemyBot);
			
			Arena(_arena.get(Arena)).sparkEmitter = new SparkParticles();
			Arena(_arena.get(Arena)).sparkEmitter.init();
			Arena(_arena.get(Arena)).sparkEntity= EmitterCreator.create(this, _hitContainer, Arena(_arena.get(Arena)).sparkEmitter, 0, 0);
			
			// make enemy bot look different - temporary
			ArenaRobot(_enemyBot.get(ArenaRobot)).body = 2;
			ArenaRobot(_enemyBot.get(ArenaRobot)).legs = 2;
			ArenaRobot(_enemyBot.get(ArenaRobot)).arms = 2;
			
			Arena(_arena.get(Arena)).cpuRobot = _enemyBot;
			
			// add robots to arena
			Arena(_arena.get(Arena)).robots.push(_playerBot);
			Arena(_arena.get(Arena)).robots.push(_enemyBot);
			
			// add interface to arena
			Arena(_arena.get(Arena)).gameInterface = _hitContainer["gameInterface"];
			Arena(_arena.get(Arena)).origPoint = new Point(Display(_arena.get(Display)).displayObject.x, Display(_arena.get(Display)).displayObject.y);
			_hitContainer["gameInterface"]["meters"]["player2name"].gotoAndStop(Arena(_arena.get(Arena)).stage+1);
			
			_hitContainer["frame"].mouseEnabled = false;
			_hitContainer["frame"].mouseChildren = false;
			
			// order layers
			_hitContainer.setChildIndex(_hitContainer["vs"], _hitContainer.numChildren - 1);
			_hitContainer.setChildIndex(_hitContainer["ko"], _hitContainer.numChildren - 1);
			_hitContainer.setChildIndex(_hitContainer["gameInterface"], _hitContainer.numChildren - 1);
			_hitContainer.setChildIndex(_hitContainer["loseMSG"], _hitContainer.numChildren - 1);
			_hitContainer.setChildIndex(_hitContainer["winLoseScreen"], _hitContainer.numChildren - 1);
			_hitContainer.setChildIndex(_hitContainer["save"], _hitContainer.numChildren - 1);
			_hitContainer.setChildIndex(_hitContainer["ladderScreen"], _hitContainer.numChildren - 1);
			_hitContainer.setChildIndex(_hitContainer["instructionsScreen"], _hitContainer.numChildren - 1);
			_hitContainer.setChildIndex(_hitContainer["megaCoinBar"], _hitContainer.numChildren - 1);
			_hitContainer.setChildIndex(_hitContainer["coinPopup"], _hitContainer.numChildren - 1);
			_hitContainer.setChildIndex(_hitContainer["startMenu"], _hitContainer.numChildren - 1);
			_hitContainer.setChildIndex(_hitContainer["frame"], _hitContainer.numChildren - 1);
			_hitContainer.setChildIndex(_hitContainer["closeButton"], _hitContainer.numChildren - 1);
			
			// add sound driver
			setupAudio();
		}		
		
		private function onMegaCoin($entity:Entity):void
		{
			if(!Display(_coinPopup.get(Display)).visible){
				Display(_coinPopup.get(Display)).visible = true;
				var coinInt:Interaction = InteractionCreator.addToEntity(_coinPopup, [InteractionCreator.DOWN]);
				coinInt.down.addOnce(onCoinPopupNorm);
			}
		}	
		
		private function onCoinPopupNorm($entity:Entity):void
		{
			Display(_coinPopup.get(Display)).visible = false;
		}
		
		private function addBaseSystems():void{
			super.addSystem(new InteractionSystem(), SystemPriorities.update);
			super.addSystem(new MotionSystem(), SystemPriorities.move);
			super.addSystem(new TimelineControlSystem());
			super.addSystem(new TimelineClipSystem());
		}
		
		private function addGameSystems():void{
			super.addSystem(new RobotSystem(_hitContainer, this), SystemPriorities.animate);
			super.addSystem(new EnemyAISystem(_hitContainer, this), SystemPriorities.postUpdate);
			super.addSystem(new ArenaSystem(_hitContainer, this), SystemPriorities.update);
		}
		
		private function setupAudio():void
		{
			var audioGroup:AudioGroup = new AudioGroup();
			
			// this sets up systems necessary for audio playback
			audioGroup.setupGroup(this, super.getData(GameScene.SOUNDS_FILE_NAME));
			
			try{
				// pre-cache music
				_soundManager.cache(SoundManager.MUSIC_PATH + "megaFightingBots-FightThemeDrumIntro96.mp3");
				_soundManager.cache(SoundManager.MUSIC_PATH + "megaFightingBots-FightTheme-loop96.mp3");
				_soundManager.cache(SoundManager.MUSIC_PATH + "megaFightingBots-FightThemeFASTupWholeStep-loop96.mp3");
				_soundManager.cache(SoundManager.MUSIC_PATH + "retro_select_03.mp3");
				
				// pre-cache sound effects
				_soundManager.cache(SoundManager.EFFECTS_PATH + "round_one_01.mp3");
				_soundManager.cache(SoundManager.EFFECTS_PATH + "round_two_01.mp3");
				_soundManager.cache(SoundManager.EFFECTS_PATH + "final_round_01.mp3");
				
				_soundManager.cache(SoundManager.EFFECTS_PATH + "robot_to_robot_impact_01.mp3");
				_soundManager.cache(SoundManager.EFFECTS_PATH + "robot_to_robot_impact_02.mp3");
				_soundManager.cache(SoundManager.EFFECTS_PATH + "robot_to_robot_impact_03.mp3");
				_soundManager.cache(SoundManager.EFFECTS_PATH + "robot_to_robot_impact_04.mp3");
				_soundManager.cache(SoundManager.EFFECTS_PATH + "robot_to_robot_impact_05.mp3");
				_soundManager.cache(SoundManager.EFFECTS_PATH + "wall_impact_01.mp3");
				_soundManager.cache(SoundManager.EFFECTS_PATH + "wall_impact_02.mp3");
				_soundManager.cache(SoundManager.EFFECTS_PATH + "over_exerted_01_L.mp3");
				_soundManager.cache(SoundManager.EFFECTS_PATH + "finishing_blow_01.mp3");
				_soundManager.cache(SoundManager.EFFECTS_PATH + "oh_01.mp3");
				_soundManager.cache(SoundManager.EFFECTS_PATH + "crowd_cheer_01.mp3");
				_soundManager.cache(SoundManager.EFFECTS_PATH + "crowd_cheer_02.mp3");
				_soundManager.cache(SoundManager.EFFECTS_PATH + "crushed_whoosh_01.mp3");
				_soundManager.cache(SoundManager.EFFECTS_PATH + "coin_up_v2_01.mp3");
			} catch ($error:Error){
				trace($error.getStackTrace());
			}
			
			// this sets up an entity that we can use to playback sounds.
			setupSoundEntity();
			
			// the AudioGroup can associate all sounds mapped to an Entity's Id to its audio component.
			audioGroup.addAudioToAllEntities();
			
			//makeEntityFollowInput(_soundEntity);
		}
		
		private function setupSoundEntity():void
		{
			_soundEntity = new Entity();
			
			// all that is needed to playback sounds from an entity is an Audio component.
			_soundEntity.add(new Audio());
			
			// adding an id to an entity allows it to be associated with sound effects specified in 'sounds.xml'.  This is not required unless you want
			//   to map sounds from sounds.xml to it.
			_soundEntity.add(new Id("soundEntity"));
			
			super.addEntity(_soundEntity);
		}
		
		private function onArena($entity:Entity):void{
			var display:DisplayObject = Display($entity.get(Display)).displayObject;
			var xIndex:int = Math.floor(display.mouseX / Arena($entity.get(Arena)).cellSize);
			var yIndex:int = Math.floor(display.mouseY / Arena($entity.get(Arena)).cellSize);
			
			var targ:DisplayObject = ArenaControl($entity.get(ArenaControl)).gridTarg;
			
			// check arena grid if valid move spot
			if(Arena($entity.get(Arena)).grid[yIndex][xIndex] != 0 && !ArenaRobot(_playerBot.get(ArenaRobot)).freeze){
				targ.visible = true;
				targ.x = (xIndex * Arena($entity.get(Arena)).cellSize) + display.x + Arena($entity.get(Arena)).cellSize/2;
				targ.y = (yIndex * Arena($entity.get(Arena)).cellSize) + display.y + Arena($entity.get(Arena)).cellSize/2;
				
				// set pathfinding
				var pathfinder:Pathfinding = new Pathfinding();
				ArenaRobot(_playerBot.get(ArenaRobot)).path = pathfinder.findPathInternal(Arena($entity.get(Arena)).grid, ArenaRobot(_playerBot.get(ArenaRobot)).moveCoord.y, ArenaRobot(_playerBot.get(ArenaRobot)).moveCoord.x, yIndex, xIndex);
				ArenaRobot(_playerBot.get(ArenaRobot)).path.pop();
			}
			
			// check for double click
			if(!ArenaRobot(_playerBot.get(ArenaRobot)).freeze && !ArenaRobot(_playerBot.get(ArenaRobot)).energyExhausted){
				if(_dblTimer == null){
					_dblTimer = new Timer(300, 1);
					_dblTimer.addEventListener(TimerEvent.TIMER_COMPLETE, endDblTimer);
					_dblTimer.start();
				} else {
					// double click detected
					var angle:Number = point_direction(Spatial(_playerBot.get(Spatial)).x, Spatial(_playerBot.get(Spatial)).y, targ.x, targ.y);
					
					if(angle > -45 && angle <= 45){
						// charge right
						ArenaRobot(_playerBot.get(ArenaRobot)).chargeDir = "right";
					} else if(angle > 135 || angle <= -135){
						// charge left
						ArenaRobot(_playerBot.get(ArenaRobot)).chargeDir = "left";
					} else if (angle <= 135 && angle > 45){
						// charge down
						ArenaRobot(_playerBot.get(ArenaRobot)).chargeDir = "down";
					} else if (angle > -135 && angle < -45){
						// charge up
						ArenaRobot(_playerBot.get(ArenaRobot)).chargeDir = "up";
					}
					
					// set new pathfinding from end space?
				}
			}
			
		}
		
		public function setInterface():void{
			var playerRobot:ArenaRobot = Arena(_arena.get(Arena)).playerRobot.get(ArenaRobot);
			var enemyRobot:ArenaRobot = Arena(_arena.get(Arena)).cpuRobot.get(ArenaRobot);
			
			_hitContainer["gameInterface"].p1Portrait.gotoAndStop(playerRobot.body);
			_hitContainer["gameInterface"].p2Portrait.gotoAndStop(enemyRobot.body);
		}
		
		public function setKO():void{
			var playerRobot:ArenaRobot = Arena(_arena.get(Arena)).playerRobot.get(ArenaRobot);
			var enemyRobot:ArenaRobot = Arena(_arena.get(Arena)).cpuRobot.get(ArenaRobot);
			
			if(playerRobot.lost){
				_hitContainer["ko"].portrait.gotoAndStop(playerRobot.body);
			} else {
				_hitContainer["ko"].portrait.gotoAndStop(enemyRobot.body);
			}
		}
		
		public function setVS():void{
			var playerRobot:ArenaRobot = Arena(_arena.get(Arena)).playerRobot.get(ArenaRobot);
			var enemyRobot:ArenaRobot = Arena(_arena.get(Arena)).cpuRobot.get(ArenaRobot);
			
			_hitContainer["vs"].p1Portrait.gotoAndStop(playerRobot.body);
			_hitContainer["vs"].p2Portrait.gotoAndStop(enemyRobot.body);
		}
		
		public function setWinLose():void{
			var playerRobot:ArenaRobot = Arena(_arena.get(Arena)).playerRobot.get(ArenaRobot);
			var enemyRobot:ArenaRobot = Arena(_arena.get(Arena)).cpuRobot.get(ArenaRobot);
			
			_hitContainer["winLoseScreen"].p1Portrait.gotoAndStop(playerRobot.body);
			if(playerRobot.lost){
				_hitContainer["winLoseScreen"].p1Portrait.portrait.gotoAndStop(2);
				_hitContainer["winLoseScreen"].winLose.gotoAndStop(2);
			} else {
				_hitContainer["winLoseScreen"].p1Portrait.portrait.gotoAndStop(1);
				_hitContainer["winLoseScreen"].winLose.gotoAndStop(1);
			}
			
			_hitContainer["winLoseScreen"].p2Portrait.gotoAndStop(enemyRobot.body);
			if(enemyRobot.lost){
				_hitContainer["winLoseScreen"].p2Portrait.portrait.gotoAndStop(2);
			} else {
				_hitContainer["winLoseScreen"].p2Portrait.portrait.gotoAndStop(1);
			}
			
		}
		
		public function playCoinUp():void{
			// show coin up vignette
			Timeline(_coinUp.get(Timeline)).play();
		}
		
		public function newRound():void{
			_hitContainer["alertMC"].gotoAndStop(1);
			Arena(_arena.get(Arena)).gameState = 1;
			centerArena();
			_gettingClose = false;
			startBattleMusic();
		}
		
		public function saveScreen():void{
			Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.CLICK;  // change default cursor
			
			var audio:Audio = AudioUtils.getAudio(this, SceneSound.SCENE_SOUND);
			audio.stopAll(SoundType.MUSIC);
			
			Display(_save.get(Display)).visible = true;
			Display(_save.get(Display)).alpha = 1;
			
			super.shellApi.triggerEvent("continue");
			var saveInt:Interaction = InteractionCreator.addToEntity(_save, [InteractionCreator.DOWN]);
			saveInt.down.addOnce(onSave);
			Timeline(_save.get(Timeline)).gotoAndPlay(1);
		}
		
		private function onSave($entity:Entity):void
		{
			Timeline(_save.get(Timeline)).stop();
			if(!_bonusQuest){
				// popup megaCoin demand screen
				Display(_coinPopup.get(Display)).visible = true;
				var coinInt:Interaction = InteractionCreator.addToEntity(_coinPopup, [InteractionCreator.DOWN]);
				coinInt.down.addOnce(onCoinPopup);
			} else {
				Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.TARGET;
				// continue game
				super.shellApi.triggerEvent("coinUp");
				_continuing = true;
				
				Display(_save.get(Display)).visible = false;
				// fade continue screen
				
				Timeline(_coinUp.get(Timeline)).play();
				
				var display:Display = _save.get(Display);
				TweenLite.to(display, 1, {alpha:0, onComplete:hideSave});
				TweenLite.to(_megaCoinBar.get(Display), 1, {alpha:0});
				
				function hideSave():void{
					Display(_save.get(Display)).visible = false;
					continueGame();
				}
			}
		}
		
		private function continueGame():void{
			Arena(_arena.get(Arena)).gameState = 1;
			centerArena();
			_gettingClose = false;
			startBattleMusic();
		}
		
		private function onCoinPopup($entity:Entity):void{
			Display(_coinPopup.get(Display)).visible = false;
			saveScreen();
		}
		
		public function gameOver($playerLost:Boolean = false):void{
			
			// reset cursor
			Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.CLICK;  // change default cursor
			
			_hitContainer["alertMC"].gotoAndStop(1);
			
			// switch to win lose screen
			if($playerLost){
				// show save screen
				// listen for whiteOut
				Timeline(_save.get(Timeline)).handleLabel("whiteout", saveOver, true);
				saveScreen();
			} else {
				// show winLose screen on WIN
				
				// check _bonusQuest
				if(_bonusQuest){
					var dialogs:MovieClip = Display(_winLose.get(Display)).displayObject["dialogs"] as MovieClip;
					dialogs.gotoAndStop("win"+Arena(_arena.get(Arena)).stage);
					dialogs.alpha = 0;
					dialogs.y += 15;
					TweenLite.to(dialogs, 0.5, {alpha:1, y:dialogs.y - 15, delay:1});
				}
				
				super.shellApi.triggerEvent("win");
				Display(_winLose.get(Display)).visible = true;
				Display(_winLose.get(Display)).alpha = 1;
				Display(_megaCoinBar.get(Display)).visible = true;
				Display(_megaCoinBar.get(Display)).alpha = 1;
				var winLoseInt:Interaction = InteractionCreator.addToEntity(_winLose, [InteractionCreator.DOWN]);
				//winLoseInt.down.addOnce(resetToStart);
				winLoseInt.down.addOnce(nextStage);
			}
		}
		
		private function saveOver():void
		{
			// show winLose screen
			
			// check _bonusQuest
			if(_bonusQuest){
				var dialogs:MovieClip = Display(_winLose.get(Display)).displayObject["dialogs"] as MovieClip;
				dialogs.gotoAndStop("lose"+Arena(_arena.get(Arena)).stage);
				dialogs.alpha = 0;
				dialogs.y += 15;
				TweenLite.to(dialogs, 0.5, {alpha:1, y:dialogs.y - 15, delay:1});
			}
			
			super.shellApi.triggerEvent("lose");
			Display(_megaCoinBar.get(Display)).alpha = 1;
			Display(_megaCoinBar.get(Display)).visible = true;
			Display(_winLose.get(Display)).alpha = 1;
			Display(_winLose.get(Display)).visible = true;
			var winLoseInt:Interaction = InteractionCreator.addToEntity(_winLose, [InteractionCreator.DOWN]);
			winLoseInt.down.addOnce(onWinLose);
		}
		
		private function endDblTimer($event:TimerEvent):void{
			_dblTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, endDblTimer);
			_dblTimer = null;
		}
		
		private function onClose($entity:Entity):void
		{
			if(super.shellApi.sceneManager.previousScene == "game.scenes.mocktropica.hangar::Hangar"){
				super.shellApi.loadScene(Hangar,300,920);
			} else if (super.shellApi.sceneManager.previousScene == "game.scenes.mocktropica.classroom::Classroom"){
				super.shellApi.loadScene(Classroom,1240,570,"right");
			} else {
				// load classroom by default
				super.shellApi.loadScene(Classroom,1240,570,"right");
			}
			
		}		
		
		private function onStartMenu($entity:Entity):void{
			super.shellApi.triggerEvent("mainStart");
			
			// fade startMenu
			var display:Display = _startMenu.get(Display);
			TweenLite.to(display, 1, {alpha:0, onComplete:hideMenu});
			
			
			function hideMenu():void{
				display.visible = false;
			}
		}
		
		private function onInstructions($entity:Entity):void
		{
			//super.shellApi.triggerEvent("mainStart");
			
			// remove popup if visible
			if(Display(_coinPopup.get(Display)).visible){
				Display(_coinPopup.get(Display)).visible = false;
			}
			
			// change music
			var audio:Audio = AudioUtils.getAudio(this, SceneSound.SCENE_SOUND);
			audio.stopAll(SoundType.MUSIC);
			super.shellApi.triggerEvent("ladderTheme");
			
			// fade instructions
			var display:Display = _instructions.get(Display);
			TweenLite.to(display, 1, {alpha:0, onComplete:hideInstructions});
			
			if(Arena(_arena.get(Arena)).stage == 1){
				MovieClip(Display(_ladder.get(Display)).displayObject).gotoAndPlay(2);
			} else {
				MovieClip(Display(_ladder.get(Display)).displayObject).gotoAndPlay("battle"+(Arena(_arena.get(Arena)).stage - 1));
			}
			
			function hideInstructions():void{
				display.visible = false;
			}
		}
		
		private function onLadder($entity:Entity):void{
			//super.shellApi.triggerEvent("mainStart");
			
			// remove popup if visible
			if(Display(_coinPopup.get(Display)).visible){
				Display(_coinPopup.get(Display)).visible = false;
			}
			
			setInterface();
			
			// fade instructions
			var display:Display = _ladder.get(Display);
			TweenLite.to(display, 1, {alpha:0, onComplete:hideLadder});
			TweenLite.to(_megaCoinBar.get(Display), 1, {alpha:0});
			
			function hideLadder():void{
				startBattleMusic();
				if(!_bonusQuest || _continuing == true){
					// start game
					_continuing = false;
					Arena(_arena.get(Arena)).gameState = 1;
					centerArena();
				} else {
					// start robot battle
					Arena(_arena.get(Arena)).playRobotDialog();
				}
				display.visible = false;
				Display(_megaCoinBar.get(Display)).visible = false;
			}
			
			// change cursor to target
			Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.TARGET;  // change default cursor
		}
		
		private function stopMusic():void{
			var audio:Audio = AudioUtils.getAudio(this, SceneSound.SCENE_SOUND);
			audio.stopAll(SoundType.MUSIC);
		}
		
		public function startBattleMusic():void{
			super.shellApi.triggerEvent("cheer");
			
			// change music
			var audio:Audio = AudioUtils.getAudio(this, SceneSound.SCENE_SOUND);
			audio.stopAll(SoundType.MUSIC);
			
			var audioSequence:AudioSequence = _soundEntity.get(AudioSequence);
			
			if(audioSequence == null)
			{
				audioSequence = new AudioSequence();
				audioSequence.loop = false;
				audioSequence.sequence.push(SoundManager.MUSIC_PATH + "megaFightingBots-FightThemeDrumIntro96.mp3");
				audioSequence.playbackComplete.add(onIntroComplete);
				_soundEntity.add(audioSequence);
				
				audioSequence.play = true;
			} else {
				audioSequence.sequence.push(SoundManager.MUSIC_PATH + "megaFightingBots-FightThemeDrumIntro96.mp3");
				audioSequence.play = true;
			}
		}
		
		private function onIntroComplete():void
		{
			super.shellApi.triggerEvent("battleLoop");
		}		
		
		
		private function onWinLose($entity:Entity):void{
			// show loseMSG
			Display(_loseMsg.get(Display)).visible = true;
			
			// fade winLose
			var display:Display = _winLose.get(Display);
			TweenLite.to(display, 1, {alpha:0, onComplete:hideWinLose});
			
			function hideWinLose():void{
				display.visible = false;
			}
		}
		
		
		private function onLoseMsg($entity):void
		{
			// popup window
			Display(_coinPopup.get(Display)).visible = true;
			var coinInt:Interaction = InteractionCreator.addToEntity(_coinPopup, [InteractionCreator.DOWN]);
			coinInt.down.addOnce(resetToStart);
		}
		
		private function nextStage($entity:Entity):void{
			// increment stage and settings:
			if(Arena(_arena.get(Arena)).stage < 5){
				_continuing = false;
				Arena(_arena.get(Arena)).gameState = 0;
				Display(_ladder.get(Display)).visible = true;
				Display(_ladder.get(Display)).alpha = 1;
				
				Display(_ladder.get(Display)).displayObject["enemies"]["bot"+Arena(_arena.get(Arena)).stage].gotoAndStop(2); // change defeated bot's portrait on ladder
				
				Arena(_arena.get(Arena)).stage++;
				
				ArenaRobot(_enemyBot.get(ArenaRobot)).newRobotStage(Arena(_arena.get(Arena)).stage);
				
				_hitContainer["gameInterface"]["meters"]["player2name"].gotoAndStop(Arena(_arena.get(Arena)).stage+1);
				
				// remove popup if visible
				if(Display(_coinPopup.get(Display)).visible){
					Display(_coinPopup.get(Display)).visible = false;
				}
				
				// change music
				super.shellApi.triggerEvent("ladderTheme");
				
				// fade winLose
				var ladderInt:Interaction = InteractionCreator.addToEntity(_ladder, [InteractionCreator.DOWN]);
				ladderInt.down.addOnce(onLadder);
				
				var display:Display = _winLose.get(Display);
				TweenLite.to(display, 1, {alpha:0, onComplete:hideWinLose});
				
				MovieClip(Display(_ladder.get(Display)).displayObject).gotoAndPlay("battle"+(Arena(_arena.get(Arena)).stage));
				
				function hideWinLose():void{
					display.visible = false;
				}
				
			} else {
				// end game
				var mocktropicaEvents:MocktropicaEvents = new MocktropicaEvents();
				
				if(!super.shellApi.checkEvent(mocktropicaEvents.DEFEATED_MFB)){
					// trigger completion event
					if (super.shellApi.checkEvent(mocktropicaEvents.BLOCKED_FROM_BONUS)) {
						super.shellApi.track("BonusQuest", "Won", "Converted", "Mocktropica");
					}
					else {
						super.shellApi.track("BonusQuest", "Won", null, "Mocktropica");
					}
					
					// trigger hertz scene
					
					super.shellApi.triggerEvent(mocktropicaEvents.DEFEATED_MFB, true);
					super.shellApi.loadScene(Hangar,420,890);
				} else {
					// return to scene
					if(super.shellApi.sceneManager.previousScene == "game.scenes.mocktropica.hangar::Hangar"){
						super.shellApi.loadScene(Hangar,300,920);
					} else {
						super.shellApi.loadScene(Classroom,1240,570,"right");
					}
					
				}
				
				
			}
		}
		
		private function resetToStart($entity:Entity):void{
			// reset to start menu
			super.shellApi.triggerEvent("mainTheme");
			_gettingClose = false;
			
			Arena(_arena.get(Arena)).gameState = 0;
			Arena(_arena.get(Arena)).stage = 1;
			centerArena();
			
			ArenaRobot(_enemyBot.get(ArenaRobot)).newRobotStage(1);
			
			Display(_startMenu.get(Display)).alpha = 1;
			Display(_startMenu.get(Display)).visible = true;
			Display(_instructions.get(Display)).alpha = 1;
			Display(_instructions.get(Display)).visible = true;
			Display(_ladder.get(Display)).alpha = 1;
			Display(_ladder.get(Display)).visible = true;
			Display(_winLose.get(Display)).alpha = 1;
			Display(_winLose.get(Display)).visible = false;
			Display(_loseMsg.get(Display)).visible = false;
			Display(_coinPopup.get(Display)).visible = false;
			Display(_megaCoinBar.get(Display)).visible = true;
			Display(_megaCoinBar.get(Display)).alpha = 1;
			
			var startMenuInt:Interaction = InteractionCreator.addToEntity(_startMenu, [InteractionCreator.DOWN]);
			startMenuInt.down.addOnce(onStartMenu);
			
			var instructionsInt:Interaction = InteractionCreator.addToEntity(_instructions, [InteractionCreator.DOWN]);
			instructionsInt.down.addOnce(onInstructions);
			
			var ladderInt:Interaction = InteractionCreator.addToEntity(_ladder, [InteractionCreator.DOWN]);
			ladderInt.down.addOnce(onLadder);
			
			var loseMsgInt:Interaction = InteractionCreator.addToEntity(_loseMsg, [InteractionCreator.DOWN]);
			loseMsgInt.down.addOnce(onLoseMsg);
		}
		
		public function centerArena():void{
			Display(_arena.get(Display)).displayObject.x = Arena(_arena.get(Arena)).origPoint.x;
			Display(_arena.get(Display)).displayObject.y = Arena(_arena.get(Arena)).origPoint.y;
		}
		
		public function bonusQuestOn():void{
			super.shellApi.log("BONUS QUEST MODE ON! 01A");
			_bonusQuest = true;
		}
		
		public function easyModeOn():void{
			var robot:ArenaRobot = Arena(_arena.get(Arena)).cpuRobot.get(ArenaRobot);
			robot.easyMode = true;
			robot.newRobotStage(Arena(_arena.get(Arena)).stage);
			super.shellApi.log("EASY MODE ON! - Enemy robot's health fractionalized");
		}
		
		public function setPlayerSpeed($speed:Number):void{
			ArenaRobot(_playerBot.get(ArenaRobot)).speed = $speed;
		}
		
		private function point_direction(x1:Number, y1:Number, x2:Number, y2:Number):Number
		{
			return Math.atan2(y2 - y1, x2 - x1) * (180 / Math.PI);
		}
		
		public function get coinUp():Entity{
			return _coinUp;
		}
		
		public function get gettingClose():Boolean{return _gettingClose;}
		public function set gettingClose($boolean:Boolean):void{_gettingClose = $boolean;}
		
		public function get cheatOn():Boolean{return _bonusQuest;}
		public function set cheatOn($boolean:Boolean):void{_bonusQuest = $boolean;}
		
		private var _dblTimer:Timer;
		
		private var _megaCoinBar:Entity;
		
		private var _startMenu:Entity;
		private var _winLose:Entity;
		private var _instructions:Entity;
		private var _ladder:Entity;
		private var _vs:Entity;
		private var _ko:Entity;
		
		private var _robotDialogs:Entity;
		
		private var _closeButton:Entity;
		
		private var _arena:Entity;
		private var _arenaInt:Interaction;
		
		private var _playerBot:Entity;
		private var _enemyBot:Entity;
		
		private var _hitContainer:DisplayObjectContainer;
		private var _target:Entity;
		private var _save:Entity;
		private var _coinPopup:Entity;
		private var _coinUp:Entity;
		
		private var _soundEntity:Entity;
		
		private var _gettingClose:Boolean = false;
		
		private var _loseMsg:Entity;
		
		private var _bonusQuest:Boolean = false;
		private var _previousScene:String;
		private var _continuing:Boolean = false;
		
		private var _overrideScene:Boolean = false;
		
		[Inject]
		public var _soundManager:SoundManager;
	}
}