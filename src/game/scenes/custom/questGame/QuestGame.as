package game.scenes.custom.questGame
{
	import flash.utils.getDefinitionByName;
	
	import game.managers.ads.AdManager;
	import game.scene.template.ads.AdInteriorScene;
	import game.scene.template.ads.AdMemoryGame;
	import game.scene.template.ads.AdSimonGame;
	import game.scene.template.ads.AdSequenceGame;
	import game.scene.template.ads.BotBreakerGame;
	import game.scene.template.ads.CollectionGame;
	import game.scene.template.ads.ObstacleGame;
	import game.scene.template.ads.RaceGame;
	import game.scene.template.ads.RaceToTheTopGame;
	import game.scene.template.ads.SkyChaseGame;
	import game.scene.template.ads.StarShooterGame;
	import game.scene.template.ads.TopDownBitmapGame;
	import game.scene.template.ads.TopDownRaceGame;
	import game.ui.hud.Hud;
	import game.ui.popup.Popup;
	import game.util.ClassUtils;
	import game.util.DataUtils;
	
	/**
	 * Class for all quest games with various game engines, such as chase or collection games
	 * @author VHOCKRI
	 */
	public class QuestGame extends AdInteriorScene
	{
		public function QuestGame()
		{
			// manifest array for game engines (update as more are added)
			var manifest:Array = [AdSequenceGame, AdMemoryGame,BotBreakerGame, RaceGame, CollectionGame, SkyChaseGame, TopDownRaceGame,
									TopDownBitmapGame, StarShooterGame, RaceToTheTopGame, ObstacleGame, AdSimonGame];
			super();
		}
		
		/**
		 * When all characters are loaded 
		 */
		override protected function allCharactersLoaded():void
		{
			// check for game data
			var vGameXML:XML = super.getData("game.xml", false);
			// if game data, get game class (must be first node in xml)
			if (vGameXML != null)
			{
				// get class path from xml
				var classPath:String = String(vGameXML.className);
				// if no dots in class path then prepend path
				if (classPath.indexOf(".") == -1)
					classPath = "game.scene.template.ads." + classPath;
				// get game class
				var vClass:Class = ClassUtils.getClassByName(classPath);
				// create game class object
				_gameClass = new vClass();
				// setup signal to trigger
				_gameClass.gameSetUp.addOnce(gameSetUp);
				// tell game class to initialize
				_gameClass.setupGame(this, vGameXML, _hitContainer);
				// set return coordinates based on game xml
				_returnX = Number(vGameXML.returnX);
				_returnY = Number(vGameXML.returnY);
				if(vGameXML.hasOwnProperty("next"))
					_nextGame = String(vGameXML.next);
				if(vGameXML.hasOwnProperty("first"))
					_firstGame = String(vGameXML.first);
			}
			else
			{
				super.allCharactersLoaded();
			}
		}
		
		public function gameSetUp(...args):void
		{
			super.allCharactersLoaded();
		}
		
		/**
		 * All assets loaded 
		 */
		override public function loaded():void
		{			
			// catch events that get triggered
			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			// trigger any initial dialog for any NPCs
			super.shellApi.triggerEvent("initScene",false, false);
			
			super.loaded();
		}
		
		/**
		 * To capture any game triggers and pass to game class
		 * @param event
		 * @param makeCurrent
		 * @param init
		 * @param removeEvent
		 */
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			trace("QuestGame: event: " + event);
			var funct:Object;
			// check if game class has public function that matches event name
			try
			{
				funct = _gameClass[event];
			}
			catch(e:Error)
			{
				trace("QuestGame: no matching function to " + event);
				return;
			}
			// call function
			funct();
		}
		
		/**
		 * Load win popup 
		 */
		public function loadWinPopup(score:Number = 0, returnToLastScene:Boolean=false):void
		{
			if(!DataUtils.validString(_nextGame))
			{
				// show hud in case hidden
				var hud:Hud = Hud(this.getGroupById(Hud.GROUP_ID));
				hud.showHudButton(true);

				super.loadGamePopup("AdWinQuestPopup", _firstGame, _returnX, _returnY, null, score,null,returnToLastScene);
			}
			else
			{
				StartNextGame(_nextGame);
			}
		}
		
		public function StartNextGame(suffix:String= ""):void
		{
			AdManager(super.shellApi.adManager).questSuffix = suffix;
			var sceneClass:Class = ClassUtils.getClassByName("game.scenes.custom.questGame.QuestGame");
			super.shellApi.loadScene(sceneClass);
		}
		
		/**
		 * Load lose popup 
		 */
		public function loadLosePopup(returnToLastScene:Boolean=false, score:Number = 0):void
		{
			// show hud in case hidden
			var hud:Hud = Hud(this.getGroupById(Hud.GROUP_ID));
			hud.showHudButton(true);
			
			super.loadGamePopup("AdLoseQuestPopup", null, _returnX, _returnY,null,score,null,returnToLastScene);
		}
		
		/**
		 * Load choose popup 
		 */
		public function loadChoosePopup():Popup
		{
			// dont want choosing a character to randomly change the suffix so second param is null
			return super.loadGamePopup("AdChoosePopup",null);
		}
		
		/**
		 * Make player selection (called from AdChoosePopup)
		 * @param selection player selection number (starts at 1) 
		 */
		public function playerSelection(selection:int):void
		{
			_playerSelection = selection;
			_gameClass.playerSelection(selection);
		}
		
		public function startCountDown():void
		{
			_gameClass.startCountDown();
		}
		
		public function get gameClass():Object { return _gameClass; };
		
		private var _returnX:Number = 0;
		private var _returnY:Number = 0;
		private var _gameClass:Object;
		private var _playerSelection:int;
		private var _nextGame:String;
		private var _firstGame:String;
	}
}