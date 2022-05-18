package game.managers.mobile
{
	import flash.utils.getTimer;
	
	import engine.command.LinearCommandSequence;
	
	import game.managers.IslandManager;
	import game.managers.islandSetupCommands.LoadScene;
	import game.managers.islandSetupCommands.PreloadIslandData;
	import game.managers.islandSetupCommands.RestoreFromProfile;
	import game.managers.islandSetupCommands.SendStartedIsland;
	import game.managers.islandSetupCommands.SetupIslandData;
	import game.managers.islandSetupCommands.StoreCurrentScene;
	import game.managers.islandSetupCommands.TrackSceneExit;
	import game.managers.islandSetupCommands.TrackSceneLoaded;
	import game.managers.islandSetupCommands.mobile.KeepSystemAwake;
	import game.managers.islandSetupCommands.mobile.LoadDLC;
	import game.managers.islandSetupCommands.mobile.QueueAdContent;
	import game.managers.islandSetupCommands.mobile.QueueIslandContent;
	import game.managers.islandSetupCommands.mobile.ResumeSystemIdle;
	import game.managers.islandSetupCommands.mobile.TrackFirstTimeStart;
	import game.util.ProxyUtils;

	public class IslandManagerMobile extends IslandManager
	{
		override public function loadScene(scene:*, playerX:Number = NaN, playerY:Number = NaN, direction:String = null, fadeInTime:Number = NaN, fadeOutTime:Number = NaN, onFailure:Function = null):void
		{
			var nextIsland:String = ProxyUtils.getIslandFromScene(scene);
			var newIsland:Boolean = (nextIsland != super.shellApi.island);
			var timeEnteredScene:Number = flash.utils.getTimer();
			var sequence:LinearCommandSequence = new LinearCommandSequence();
			if( onFailure == null ) { onFailure = super.onFailureDefault; };

			//sequence.add( new FadeOutCurrentScene(super.shellApi) );
			sequence.add( new KeepSystemAwake());
			sequence.add( new TrackSceneExit(scene, timeEnteredScene, super.shellApi) );
			sequence.add( new QueueAdContent(super.shellApi, nextIsland, newIsland) );
			sequence.add( new QueueIslandContent(super.shellApi, nextIsland, super.gameData, newIsland, onFailure) );
			// NOTE :: If we need to load or decompress content probably want to display loading screen
			sequence.add( new LoadDLC(super.shellApi, nextIsland, onFailure) );
			//sequence.add( new ValidateAds(super.shellApi, nextIsland, newIsland) );
			sequence.add( new PreloadIslandData(scene, super.shellApi, super.gameData, newIsland) );
			sequence.add( new SetupIslandData(nextIsland, super.shellApi, newIsland) );
			sequence.add( new RestoreFromProfile(super.shellApi.profileManager.active, nextIsland, super.shellApi, newIsland) );
			sequence.add( new SendStartedIsland(super.shellApi.profileManager.active, nextIsland, super.shellApi, super.gameData) );
			sequence.add( new LoadScene(scene, playerX, playerY, direction, super.shellApi, fadeInTime, fadeOutTime) );
			sequence.add( new StoreCurrentScene(super.shellApi) );
			sequence.add( new TrackSceneLoaded(timeEnteredScene, super.shellApi, super.shellApi.island, nextIsland, this) );
			sequence.add( new TrackFirstTimeStart(super.shellApi) );
			sequence.add( new ResumeSystemIdle());
			
			sequence.start();
		}
	}
}