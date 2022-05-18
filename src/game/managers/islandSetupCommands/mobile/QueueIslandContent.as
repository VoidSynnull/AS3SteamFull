package game.managers.islandSetupCommands.mobile
{
	import com.poptropica.AppConfig;
	
	import engine.ShellApi;
	import engine.command.CommandStep;
	import engine.group.Scene;
	
	import game.data.dlc.PackagedFileState;
	import game.data.game.GameData;
	import game.managers.DLCManager;

	/**
	 * LoadDLCContent
	 *
	 * Loads the content for a new island via the DLCManager.  Sends the user to the map if content needs to be loaded from the
	 *  server.  In that case the loadScene sequence will end here.
	 */

	public class QueueIslandContent extends CommandStep
	{
		/**
		 * Start command to get ad content for island
		 * @param island - island being opened
		 * @param shellApi
		 * @param gameData
		 * @param newIsland - flag determining if new, essentailly if the next island is not equal to current island
		 *
		 */
		public function QueueIslandContent(shellApi:ShellApi, island:String, gameData:GameData, isNewIsland:Boolean = true, onFailure:Function = null)
		{
			super();

			_island = island;
			_shellApi = shellApi;
			_gameData = gameData;
			_isNewIsland = isNewIsland;
			_onFailure = onFailure;
		}

		override public function execute():void
		{
			// if content is not yet installed
			if( _isNewIsland )
			{
				var dlcManager:DLCManager = _shellApi.getManager(DLCManager) as DLCManager;
				if( !dlcManager.isInstalled(_island) )
				{
					// if the content requires remote content, go to the map and download it.
					if(dlcManager.getPackagedFileState(_island) == PackagedFileState.REMOTE_COMPRESSED)
					{
						if( AppConfig.debug && AppConfig.forceMobile )
						{
							trace( this," :: DEBUG :: skip content load when forcing mobile" );
							super.complete();
						}
						else
						{
							// NOTE :: This clears any content queued thus far, at this point should only be ad content in queue
							// Want to keep an eye on this, requires testing
							dlcManager.clearQueue();
							redirectToMap();
						}
					}
					else
					{
						dlcManager.queueContentById(_island);
						super.complete();
					}
				}
				else
				{
					trace( "LoadDLCContent : island " + _island + " is already installed, no need to load content" );
					super.complete();
				}
			}
			else
			{
				trace( "LoadDLCContent : island " + _island + " is not changing, no need to load content" );
				super.complete();
			}
		}

		/**
		 * Redirects to Map
		 */
		private function redirectToMap():void
		{
			var mapClass:Class = _gameData.mapClass;
			var mapScene:Scene = new mapClass();
			mapScene['autoLoadIsland'] = _island;
			//_shellApi.sceneManager.loadScene(mapScene);	// NOTE :: do we really want to laod map in this way? - bard
			_shellApi.loadScene(mapScene, NaN, NaN, null, NaN, NaN, _onFailure );

			// if we need to return to the map to load content, short-circuit the scene-load sequence.
			trace( "LoadDLCContent : island " + _island + " requires content download redirect to map, end command sequence" );
			super.completeAll();
		}

		private var _onFailure:Function;
		private var _island:String;
		private var _shellApi:ShellApi;
		private var _gameData:GameData;
		private var _isNewIsland:Boolean;
	}
}
