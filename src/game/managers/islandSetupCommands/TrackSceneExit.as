package game.managers.islandSetupCommands
{
	import flash.utils.getTimer;
	
	import engine.ShellApi;
	import engine.command.CommandStep;
	
	import game.data.ads.AdData;
	import game.util.ProxyUtils;

	/**
	 * TrackSceneExit
	 * 
	 * Tracks scene stats upon exitting a scene.
	 */
	
	public class TrackSceneExit extends CommandStep
	{
		private var _newScene:*;
		private var _timeEnteredScene:Number;
		private var _shellApi:ShellApi;

		public function TrackSceneExit(newScene, timeEnteredScene:Number, shellApi:ShellApi)
		{
			super();
			
			_newScene = newScene;
			_timeEnteredScene = timeEnteredScene;
			_shellApi = shellApi;
		}
		
		override public function execute():void
		{
			var currentIsland:String 	= _shellApi.island;
			var nextIsland:String 		= ProxyUtils.getIslandFromScene(_newScene);
			var sceneName:String 		= ProxyUtils.convertSceneToServerFormat(_newScene);
			sceneName 					= sceneName.substr(0,1).toUpperCase() + sceneName.substr(1);
			
			if(currentIsland != null && (_shellApi.sceneName != sceneName || currentIsland != nextIsland))
			{
				var timeInSeconds:int = Math.round((getTimer() - _timeEnteredScene) / 1000);
				var adData:AdData = null;
				if (currentIsland == "americanGirl" || currentIsland == "custom") {
					adData = _shellApi.adManager.getAdData(_shellApi.adManager.mainStreetType, false, false);
				}
				if(adData != null && _shellApi.arcadeGame == null) {
					_shellApi.track("TimeSpentInScene", _shellApi.sceneName, _shellApi.islandName, adData.campaign_name, "TimeSpent", timeInSeconds);
				}
				else {
					_shellApi.track("TimeSpentInScene", _shellApi.sceneName, _shellApi.islandName, null, "TimeSpent", timeInSeconds);
				}
				
				_shellApi.track("TimeSpentInScene", null, null, null, "TimeSpent", timeInSeconds);
			}
			
			super.complete();
		}
	}
}