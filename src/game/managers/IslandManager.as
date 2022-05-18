package game.managers
{
	import flash.utils.getTimer;
	
	import engine.Manager;
	import engine.command.LinearCommandSequence;
	
	import game.data.game.GameData;
	import game.managers.interfaces.IIslandManager;
	import game.managers.islandSetupCommands.LoadFiles;
	import game.managers.islandSetupCommands.LoadScene;
	import game.managers.islandSetupCommands.PreloadIslandData;
	import game.managers.islandSetupCommands.RestoreFromProfile;
	import game.managers.islandSetupCommands.SetupIslandData;
	import game.managers.islandSetupCommands.StoreCurrentScene;
	import game.managers.islandSetupCommands.TrackSceneExit;
	import game.managers.islandSetupCommands.TrackSceneLoaded;
	import game.scene.template.DoorGroup;
	import game.ui.hud.Hud;
	import game.util.CharUtils;
	import game.util.ProxyUtils;
	import game.util.SceneUtil;

	public class IslandManager extends Manager implements IIslandManager
	{
		public function IslandManager()
		{
			super();
		}

		public function loadScene(scene:*, playerX:Number = NaN, playerY:Number = NaN, direction:String = null, fadeInTime:Number = NaN, fadeOutTime:Number = NaN, onFailure:Function = null):void
		{
			var nextIsland:String = ProxyUtils.getIslandFromScene(scene);
			var newIsland:Boolean = (nextIsland != super.shellApi.island);
			var timeEnteredScene:Number = flash.utils.getTimer();
			var sequence:LinearCommandSequence = new LinearCommandSequence();
			if( onFailure == null ) { onFailure = onFailureDefault; };
			
			sequence.add( new TrackSceneExit(scene, timeEnteredScene, super.shellApi) );
			sequence.add( new PreloadIslandData(scene, super.shellApi, _gameData, newIsland) );
			sequence.add( new SetupIslandData(nextIsland, super.shellApi, newIsland) );
			sequence.add( new RestoreFromProfile(super.shellApi.profileManager.active, nextIsland, super.shellApi, newIsland) );
			sequence.add( new LoadScene(scene, playerX, playerY, direction, super.shellApi, fadeInTime, fadeOutTime) );
			sequence.add( new StoreCurrentScene(super.shellApi) );
			sequence.add( new TrackSceneLoaded(timeEnteredScene, super.shellApi, super.shellApi.island, nextIsland, this) );

			sequence.start();
		}

		/**
		 * Default handler for a failure to load new scene, unlocks controls and character control
		 * @param args
		 */
		protected function onFailureDefault(...args):void
		{
			if( shellApi.currentScene )
			{
				SceneUtil.lockInput( shellApi.currentScene, false, false );
			}
			if( shellApi.player )
			{
				CharUtils.lockControls( shellApi.player, false, false );
			}
		}

		public function loadAndSetupDataForIsland(island:String, callback:Function = null, onFailure:Function = null):void
		{
			var prefix:String = super.shellApi.dataPrefix + "scenes/" + island;
			var islandConfig:String = prefix + "/island.xml";

			// check to see if this islands data has been loaded yet before proceeding.
			if(super.shellApi.getFile(islandConfig) == null)
			{
				var eventGroups:String 	= prefix + "/eventGroups.xml";
				var islandFiles:Array = new Array(islandConfig, eventGroups);
				var sequence:LinearCommandSequence = new LinearCommandSequence();
				sequence.completed.addOnce(callback);

				sequence.add( new LoadFiles(islandFiles, super.shellApi) );
				sequence.add( new SetupIslandData(island, super.shellApi, true) );
				//sequence.add( new RestoreFromProfile(super.shellApi.profileManager.active, island, super.shellApi, true) );
				sequence.start();
			}
			else
			{
				if(callback)
				{
					callback();
				}
			}
		}

		public function get gameData():GameData { return this._gameData; }
		public function set gameData(gameData:GameData):void
		{
			if(!_gameData)
			{
				_gameData = gameData;
			}
		}

		private var _gameData:GameData;
		public var lastTime:Number = 0;
		
		// classes that define

		public var _hudGroupClass:Class = Hud;
		public function get hudGroupClass():Class				{ return _hudGroupClass; }
		public function set hudGroupClass( value:Class):void	{ _hudGroupClass = value; }

		public var _doorGroupClass:Class = DoorGroup;
		public function get doorGroupClass():Class				{ return _doorGroupClass; }
		public function set doorGroupClass( value:Class):void	{ _doorGroupClass = value; }
	}
}
