package game.managers.islandSetupCommands
{
	import flash.utils.getTimer;
	
	import engine.ShellApi;
	import engine.command.CommandStep;
	
	import game.data.TrackingEvents;
	import game.util.PlatformUtils;
	import game.managers.interfaces.IIslandManager;
	import game.managers.IslandManager;

	/**
	 * TrackSceneLoaded
	 * 
	 * Tracks scene loading stats upon loading a scene.
	 * @author Billy Belfied
	 */
	public class TrackSceneLoaded extends CommandStep
	{
		public function TrackSceneLoaded(timeEnteredScene:Number, shellApi:ShellApi, currentIsland, nextIsland:String, manager:IIslandManager)
		{
			super();
			
			_timeEnteredScene = timeEnteredScene;
			_shellApi = shellApi;
			_currIsland = currentIsland;
			_nextIsland = nextIsland;
			_islandManager = manager;
		}
		
		override public function execute():void
		{
			if(!PlatformUtils.inBrowser)
			{			
				_shellApi.track("LoadingDuration", _shellApi.sceneName, _shellApi.island, null, "LoadingDuration", getTimer() - _timeEnteredScene);
			}
			
			// timer for lego island -------------------------
			if (_nextIsland == "lego" || _nextIsland == "americanGirl")
			{
				// start timer
				_shellApi.legoStart = flash.utils.getTimer();
			}
			// end timer
			else
			{
				// if current island is lego, then add more time
				if (_currIsland == "lego")
				{
					var elapsed:Number = _timeEnteredScene - _shellApi.legoStart;
					_shellApi.legoTime += elapsed;
				}
				// if not custom island for ads
				if (_nextIsland != "custom")
				{
					// if time to track
					if (_shellApi.legoTime != 0)
					{
						// track time spent in seconds
						var time:Number = Math.round(_shellApi.legoTime/1000);
						_shellApi.adManager.track(_nextIsland + "Island", "TotalTime", null, null, "TimeSpent", time);
					}
					_shellApi.legoTime = 0;
				}
			}
			//------------ end timer
			
			// feed the brain tracker
			_shellApi.track(TrackingEvents.SCENE_LOADED, _shellApi.islandName, _shellApi.sceneName);
			// this call notifies Google Analytics
			_shellApi.trackPageView();	
			
			// remember time
			IslandManager(_islandManager).lastTime = _timeEnteredScene;
			
			super.complete();
		}
		
		private var _timeEnteredScene:Number;
		private var _shellApi:ShellApi;
		private var _currIsland:String;
		private var _nextIsland:String;
		private var _islandManager:IIslandManager;
	}
}