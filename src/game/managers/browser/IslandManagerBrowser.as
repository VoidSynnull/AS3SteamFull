package game.managers.browser
{
	import com.poptropica.AppConfig;
	
	import flash.net.SharedObject;
	import flash.utils.getTimer;
	
	import engine.command.LinearCommandSequence;
	
	import game.managers.IslandManager;
	import game.managers.islandSetupCommands.GetAds;
	import game.managers.islandSetupCommands.LoadScene;
	import game.managers.islandSetupCommands.PreloadIslandData;
	import game.managers.islandSetupCommands.RestoreFromProfile;
	import game.managers.islandSetupCommands.SendStartedIsland;
	import game.managers.islandSetupCommands.SetupIslandData;
	import game.managers.islandSetupCommands.StoreCurrentScene;
	import game.managers.islandSetupCommands.TrackSceneExit;
	import game.managers.islandSetupCommands.TrackSceneLoaded;
	import game.managers.islandSetupCommands.browser.GetIslandDataFromServer;
	import game.proxy.browser.AdProxyUtils;
	import game.util.ProxyUtils;
	import game.utils.AdUtils;

	public class IslandManagerBrowser extends IslandManager
	{
		override public function loadScene(scene:*, playerX:Number = NaN, playerY:Number = NaN, direction:String = null, fadeInTime:Number = NaN, fadeOutTime:Number = NaN, onFailure:Function = null):void
		{
			var nextIsland:String = ProxyUtils.getIslandFromScene(scene);
			var newIsland:Boolean = (nextIsland != super.shellApi.island);
			var timeEnteredScene:Number = flash.utils.getTimer();
			var sequence:LinearCommandSequence = new LinearCommandSequence();
			if( onFailure == null ) { onFailure = super.onFailureDefault; };

			trace( this," :: loadScene : nextIsland : " + nextIsland + " is new island: " + newIsland );
			
			// if new island then clear campaigns
			if (newIsland) {
				if (!AppConfig.mobile)
				{
					var campaigns:SharedObject = AdUtils.campaignsLSO;
					campaigns.clear();
					AdProxyUtils.cleanOutCampaignData();
				}
			}
			
			//sequence.add( new FadeOutCurrentScene(super.shellApi) );
			sequence.add( new TrackSceneExit(scene, this.lastTime, super.shellApi) );
			sequence.add( new GetAds(super.shellApi, nextIsland, newIsland) );
			sequence.add( new PreloadIslandData(scene, super.shellApi, super.gameData, newIsland) );
			sequence.add( new SetupIslandData(nextIsland, super.shellApi, newIsland) );
			sequence.add( new GetIslandDataFromServer(super.shellApi.profileManager.active, nextIsland, super.shellApi, newIsland) );
			sequence.add( new RestoreFromProfile(super.shellApi.profileManager.active, nextIsland, super.shellApi, newIsland) );
			sequence.add( new SendStartedIsland(super.shellApi.profileManager.active, nextIsland, super.shellApi, super.gameData) );
			sequence.add( new LoadScene(scene, playerX, playerY, direction, super.shellApi, fadeInTime, fadeOutTime) );
			sequence.add( new StoreCurrentScene(super.shellApi) );
			sequence.add( new TrackSceneLoaded(timeEnteredScene, super.shellApi, super.shellApi.island, nextIsland, this) );
			//sequence.add( new CheckRegistration(super.shellApi, nextIsland) ); // RLH: don't need this anymore
			
			sequence.start();
		}
	}
}