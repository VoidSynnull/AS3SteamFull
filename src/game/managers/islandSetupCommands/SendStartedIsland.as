package game.managers.islandSetupCommands
{
	import engine.ShellApi;
	import engine.command.CommandStep;
	
	import game.data.game.GameData;
	import game.data.game.GameEvent;
	import game.data.profile.ProfileData;
	import game.proxy.DataStoreRequest;
	import game.util.PlatformUtils;
	
	/**
	 * SendStartedIsland
	 * 
	 * This logs a 'started' event for a new island (if it hasn't been started yet) 
	 * and lets the server know the new island has been started. 
	 * 
	 */
	
	public class SendStartedIsland extends CommandStep
	{
		public function SendStartedIsland(profileData:ProfileData, island:String, shellApi:ShellApi, gameData:GameData)
		{
			super();
			
			_profileData = profileData;
			_island = island;
			_shellApi = shellApi;
			_gameData = gameData;
		}
		
		override public function execute():void
		{
			// if not guest and 'real' island (not map or start)
			if(_gameData.islands.indexOf(_island) > -1)
			{
				var couldCompleteIslandStart:Boolean = _shellApi.completeEvent(GameEvent.STARTED, _island);
				if (couldCompleteIslandStart) 
				{
					_shellApi.track("IslandStarted", _island);
					if(!_profileData.isGuest)// && PlatformUtils.inBrowser)
					{
						_shellApi.siteProxy.store(DataStoreRequest.islandStartStorageRequest(_island));
					}
				}
			}
			
			super.complete();
		}
		
		private var _profileData:ProfileData;
		private var _island:String;
		private var _shellApi:ShellApi;
		private var _gameData:GameData;
	}
}