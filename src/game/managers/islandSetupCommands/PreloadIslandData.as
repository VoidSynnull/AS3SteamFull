package game.managers.islandSetupCommands
{
	import engine.ShellApi;
	import engine.command.CommandStep;
	
	import game.data.ads.AdvertisingConstants;
	import game.data.game.GameData;
	import game.util.ProxyUtils;
	
	/**
	 * PreloadScene
	 * 
	 * Sets the island and scene properties in shellApi and loads the necessary data if the scene is on a new island.
	 * @author Billy Belfield
	 */

	public class PreloadIslandData extends CommandStep
	{
		public function PreloadIslandData(nextScene:*, shellApi:ShellApi, gameData:GameData, newIsland:Boolean = true)
		{
			super();
			
			_nextScene = nextScene;
			_shellApi = shellApi;
			_gameData = gameData;
			_newIsland = newIsland;
		}
				
		override public function execute():void
		{
			var islandFiles:Array 	= new Array();
			var nextIsland:String 	= ProxyUtils.getIslandFromScene(_nextScene);
			var sceneName:String 	= ProxyUtils.convertSceneToServerFormat(_nextScene);
			sceneName 				= sceneName.substr(0,1).toUpperCase() + sceneName.substr(1);

			_shellApi.island = nextIsland;
			_shellApi.sceneName = sceneName;
			
			// RLH: don't process custom islands for ads - Would be nice to identify this in some other way...maybe Map.loadScene calls a diff version for ads?
			if (_newIsland && nextIsland != AdvertisingConstants.AD_ISLAND.toLowerCase())	// NOTE : Not sure if lowercase is necessary, just what was there
			{
				//Drew - In general, there should be an language.xml for every island, which needs to get
				//loaded on every island change before dialog, text, etc. starts trying to find things.
				var language:String 	= _shellApi.preferredLanguage;
				var languageFile:String = _shellApi.dataPrefix + "languages/" + language + "/islands/" + nextIsland + "/language.xml";
				islandFiles.push(languageFile);
				
				// check to see if this is a valid game island before saving
				if ((_gameData.islands.indexOf(nextIsland) > -1) && ('MegaFightingBots' != sceneName))
				{	
					var islandConfig:String = _shellApi.dataPrefix + "scenes/" + _shellApi.island + "/island.xml";
					var eventGroups:String 	= _shellApi.dataPrefix + "scenes/" + _shellApi.island + "/eventGroups.xml";
					islandFiles.push(islandConfig, eventGroups);
				}
				else
				{
					trace(this," :: WARNING : island:" + nextIsland + " not in list of valid islands: " + _gameData.islands );
					// TODO :: Feel liek we should have error handling here, but the start 'island' doesn't have these files
					
					/*
					// if island is not valid, return to map
					var mapClass:Class = _gameData.mapClass;
					var mapScene:Scene = new mapClass();
					_shellApi.sceneManager.loadScene(mapScene);
					
					// if we need to return to the map to load content, short-circuit the scene-load sequence.
					trace( this," :: loading to map scene as fallback" );
					super.completeAll();
					*/
				}
				
				if(islandFiles.length > 0)
				{
					loadIslandData(islandFiles);
					return;
				}
			}
			
			//If we don't have to load any files, then there's nothing to preload and this step is done.
			super.complete();
		}
		
		private function loadIslandData(files:Array):void
		{
			_shellApi.loadFiles(files, super.complete);
		}
			
		private var _shellApi:ShellApi;
		private var _nextScene:*;
		private var _gameData:GameData;
		private var _newIsland:Boolean;
	}
}