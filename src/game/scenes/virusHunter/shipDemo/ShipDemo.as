package game.scenes.virusHunter.shipDemo
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.data.TimedEvent;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.shared.ShipGroup;
	import game.scenes.virusHunter.shared.ShipScene;
	import game.scenes.virusHunter.shared.components.EnemySpawn;
	import game.scenes.virusHunter.shared.components.EnemyWaves;
	import game.scenes.virusHunter.shared.creators.PickupCreator;
	import game.scenes.virusHunter.shared.data.EnemyWaveParser;
	import game.scenes.virusHunter.shared.data.PickupType;
	import game.scenes.virusHunter.shared.systems.EnemyEyeSystem;
	import game.scenes.virusHunter.shared.systems.EnemyWaveSystem;
	import game.scenes.virusHunter.shared.systems.ShipDamageSystem;
	import game.scenes.virusHunter.shipDemo.popups.EndPopup;
	import game.scenes.virusHunter.shipDemo.popups.StartPopup;
	import game.scenes.virusHunter.shipDemo.systems.EnemyGroupSystem;
	import game.scenes.virusHunter.shipDemo.systems.OverlordEnemySystem;
	import game.scenes.virusHunter.shipDemo.systems.ScoreSystem;
	import game.scenes.virusHunter.shipDemo.systems.SeekerEnemySystem;
	import game.scenes.virusHunter.shipDemo.systems.ShooterEnemySystem;
	import game.scenes.virusHunter.shipDemo.systems.SnakeEnemySystem;
	import game.scenes.virusHunter.shipDemo.systems.SpinnerEnemySystem;
	import game.systems.SystemPriorities;
	import game.ui.popup.CharacterDialogWindow;
	import game.ui.popup.Popup;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	
	public class ShipDemo extends ShipScene
	{
		public function ShipDemo(replay:Boolean = false)
		{
			super();
			_replay = replay;
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/virusHunter/shipDemo/";
			
			super.shellApi.completeEvent(VirusHunterEvents(super.shellApi.islandEvents).GOT_SCALPEL);
			super.shellApi.completeEvent(VirusHunterEvents(super.shellApi.islandEvents).GOT_SHIELD);
			super.shellApi.completeEvent(VirusHunterEvents(super.shellApi.islandEvents).GOT_ANTIGRAV);
			
			super.init(container);
			
			super._useHud = false;
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			var shipGroup:ShipGroup = super.getGroupById("shipGroup") as ShipGroup;
			
			super.addSystem(new EnemyWaveSystem(shipGroup.enemyCreator), SystemPriorities.lowest);
			
			super.addSystem(new OverlordEnemySystem(shipGroup.enemyCreator), SystemPriorities.move);
			super.addSystem(new SeekerEnemySystem(shipGroup.enemyCreator), SystemPriorities.move);
			super.addSystem(new ShooterEnemySystem(shipGroup.enemyCreator), SystemPriorities.move);
			super.addSystem(new SnakeEnemySystem(shipGroup.enemyCreator), SystemPriorities.move);
			super.addSystem(new SpinnerEnemySystem(shipGroup.enemyCreator), SystemPriorities.move);
			super.addSystem(new EnemyEyeSystem(), SystemPriorities.move);
			//super.addSystem(new IKSystem(), SystemPriorities.move);
			
			_pickupCreator = new PickupCreator(this, super._hitContainer);
			super.addSystem(new EnemyGroupSystem(_pickupCreator), SystemPriorities.update);
			
			var hud:GameHud = super.addChildGroup(new GameHud(super.overlayContainer)) as GameHud;
			
			hud.ready.addOnce(setupScoreSystem);
			
			var shipDamageSystem:ShipDamageSystem = super.getSystem(ShipDamageSystem) as ShipDamageSystem;
			shipDamageSystem.gameover.addOnce(gameOver);
			
			/*
			var path:Vector.<Point> = new Vector.<Point>;
			
			path.push(new Point(1000, 1820));
			path.push(new Point(1200, 1820));
			path.push(new Point(1200, 1620));
			path.push(new Point(1000, 1820));
			
			CharUtils.followPath(super.shellApi.player, path, null, false); 
			*/
			
			CharUtils.lockControls(super.shellApi.player);
		}
		
		private function setupScoreSystem(hud:GameHud):void
		{
			super.addSystem(new ScoreSystem(hud.scoreDisplay), SystemPriorities.update);
			hud.screen.mouseChildren = false;
			hud.screen.mouseEnabled = false;
		}
		
		private function start():void
		{
			var popup:StartPopup = super.addChildGroup(new StartPopup(super.overlayContainer)) as StartPopup;
			popup.startSignal.add(handleStart);
			popup.openPanel.add( handlePanelOpen );
			popup.closePanel.add( handlePanelClose );
			popup.panelClang.add( handlePanelClang );
			popup.buttonClick.add( handleButtonClick );
			popup.screenStatic.add( handleStatic );
			popup.loadScreen.add( handleLoadScreen );
			popup.switchLights.add( handleSwitchLights );
			popup.id = "startPopup";
		}
		
		/******************************************************************************
		 POPUP SOUNDS
		*/
		
		private function handlePanelOpen( ...args ):void
		{
			super.shellApi.triggerEvent( "open_panel" );
		}
		
		private function handlePanelClose( ...args ):void
		{
			super.shellApi.triggerEvent( "close_panel" );
		}
		
		private function handlePanelClang( ...args ):void
		{
			super.shellApi.triggerEvent( "panel_clang" );
		}
		
		private function handleButtonClick( ...args ):void
		{
			super.shellApi.triggerEvent( "button_click" );
		}
		
		private function handleStatic( ...args ):void
		{
			super.shellApi.triggerEvent( "screen_static" );
		}
		
		private function handleLoadScreen( ... args ):void
		{
			super.shellApi.triggerEvent( "load_screen" );
		}
		
		private function handleSwitchLights( ...args ):void
		{
			super.shellApi.triggerEvent( "switchLights" );
		}
		
		private function handleVictory( ...args ):void
		{
			super.shellApi.triggerEvent( "victory" );
		}
		
		/******************************************************************************/	
		private function gameOver(win:Boolean = false):void
		{
			super.shellApi.triggerEvent("game_over");
			SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, Command.create(showGameOverPopup, win)));
			
			
			var enemyWaves:EnemyWaves = _waves.get(EnemyWaves);
			
			if(win)
			{
				super.shellApi.track("Win", enemyWaves.waveIndex, null, "VirusHunterPromo");
			}
			else
			{
				super.shellApi.track("Lose", enemyWaves.waveIndex, null, "VirusHunterPromo");
			}
		}
		
		private function showGameOverPopup(win:Boolean = false):void
		{
			var scoreSystem:ScoreSystem = super.getSystem(ScoreSystem) as ScoreSystem;
			var popup:EndPopup = super.addChildGroup(new EndPopup(super.overlayContainer, win, scoreSystem.score, _totalWaves)) as EndPopup;
			popup.playAgainClicked.add(handleReplay);
			popup.closePanel.add( handlePanelClose );
			popup.loadScreen.add( handleLoadScreen );
			popup.screenStatic.add( handleStatic );
			popup.buttonClick.add( handleButtonClick );
			popup.beatGame.add( handleVictory );
			popup.id = "endPopup";
		}
		
		private function handleStart(...args):void
		{
			var popup:Popup = super.getGroupById("startPopup") as Popup;
			popup.popupRemoved.addOnce(startGame);
			popup.close();
			
		}
		
		private function startGame():void
		{
			playIntroDialog();
			
			var spawn:EnemySpawn = new EnemySpawn(null, 1, new Rectangle(0, 0, super.shellApi.viewportWidth, super.shellApi.viewportHeight), super.shellApi.player.get(Spatial));
			spawn.distanceFromAreaEdge = 100;
			var enemyWaves:EnemyWaves = new EnemyWaves();
			var enemyWaveParser:EnemyWaveParser = new EnemyWaveParser();
			
			enemyWaves.pauseWaveCreation = true;
			enemyWaves.waveIndex = 0;
			enemyWaves.waves = enemyWaveParser.parse(super.getData("enemyWaves.xml", true));
			enemyWaves.allWavesDestroyed.add(handleAllWavesDestroyed);
			enemyWaves.waveDestroyed.add(handleWaveDestroyed);
			enemyWaves.reachedBoss.add(handleReachedBoss);
			
			_waves = new Entity();
			_waves.add(new Id("waves"));
			_waves.add(spawn);
			_waves.add(enemyWaves);
			
			super.addEntity(_waves);
		}
		
		private function handleReplay(...args):void
		{
			super.shellApi.loadScene(new ShipDemo(true));
		}
		
		private function handleReachedBoss(wave:Number):void
		{
			playMessage("boss" + (wave + 1));
			super.shellApi.triggerEvent("boss_fight");
			super.shellApi.track("ReachedBoss", wave, null, "VirusHunterPromo");
		}
		
		private function handleAllWavesDestroyed():void
		{
			gameOver(true);
		}
		
		private function handleWaveDestroyed(wave:Number):void
		{
			super.shellApi.triggerEvent("boss_defeated");
			
			var enemyWaves:EnemyWaves = _waves.get(EnemyWaves);
			var hud:GameHud = super.getGroupById("gameHud") as GameHud;
			
			hud.waveDisplay.text = String(Number(wave + 1));

			playMessage("wave" + (wave + 1));
			_totalWaves = wave + 1;
			
			var spatial:Spatial = super.shellApi.player.get(Spatial);
			
			_pickupCreator.create(spatial.x + 100, spatial.y + 100, PickupType.HEALTH);
			_pickupCreator.create(spatial.x - 100, spatial.y + 100, PickupType.UPGRADE);
			
			super.shellApi.triggerEvent( "clearWave" );
			
			super.shellApi.track("WaveCleared", wave - 1, null, "VirusHunterPromo");
			
			//var shipGroup:ShipGroup = super.getGroupById("shipGroup") as ShipGroup;
			//shipGroup.entityPool.empty(this);
		}
				
		override protected function characterDialogWindowReady(charDialog:CharacterDialogWindow):void
		{
			super.characterDialogWindowReady(charDialog);
			begin();
		}
		
		private function begin():void
		{
			//_replay = true;
			
			if(_replay)
			{
				startGame();
				startWave();
				super.shellApi.track("Replay", null, null, "VirusHunterPromo");
			}
			else
			{
				start();
				super.shellApi.track("Start", null, null, "VirusHunterPromo");
			}
			
			CharUtils.lockControls(super.shellApi.player, false, false);
			
			//playIntroDialog();
		}
				
		override public function playMessage(dialog:String, useCharacter:Boolean = true, graphicsFrame:String = null, characterId:String = null, callback:Function = null):void
		{
			super._dialogWindow.messageComplete.addOnce(startWave);
			super.playMessage( dialog, true, true );
		}
		
		private function playIntroDialog():void
		{
			super.playMessage("instruct" + _instructionIndex);
			
			if(_instructionIndex == 4)
			{
				super._dialogWindow.messageComplete.addOnce(startWave);
			}
			else
			{
				super._dialogWindow.messageComplete.addOnce(playIntroDialog);
				_instructionIndex++;
			}
		}
		
		private function startWave():void
		{
			if(_waves)
			{
				var enemyWaves:EnemyWaves = _waves.get(EnemyWaves);
				enemyWaves.pauseWaveCreation = false;
			}
		}
		
		public var _totalWaves:Number = 1;
		private var _instructionIndex:Number = 0;
		private var _waves:Entity;
		private var _replay:Boolean = false;
		private var _pickupCreator:PickupCreator;
	}
}