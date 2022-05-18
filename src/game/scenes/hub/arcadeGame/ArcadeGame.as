package game.scenes.hub.arcadeGame
{
	import flash.display.DisplayObjectContainer;
	
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdData;
	import game.data.ads.CampaignData;
	import game.managers.ads.AdManager;
	import game.scene.template.GameScene;
	import game.scenes.custom.TwitchGamePower;
	import game.scenes.custom.AdStartQuestPopup;
	import game.ui.popup.Popup;
	import game.scenes.custom.TargetShootingGamePower;
	
	public class ArcadeGame extends GameScene
	{
		public function ArcadeGame()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/hub/arcadeGame/";
			super.init(container);
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			openGamePopup();
		}
		
		private function openGamePopup():void
		{
			var gameID:String = super.shellApi.arcadeGame;
			var popup:Popup;
			switch (gameID)
			{
				case "Poptastic":
					
					// this game is a popup game that includes the start, win, and lose popups in one file
					// create popup and add to scene
					popup = shellApi.sceneManager.currentScene.addChildGroup(new TwitchGamePower()) as Popup;
					
					// create campaign data
					var data:CampaignData = new CampaignData();
					data.campaignId = "ArcadePoptastic";
					popup.campaignData = data;
					
					// create popup data
					popup.data = new Object();
					popup.data.param1 = "ArcadePoptastic/Game.xml";
					popup.data.swfPath = "ArcadePoptastic/Game.swf";
					
					// initialize popup
					popup.init( shellApi.sceneManager.currentScene.overlayContainer );
					break;
				
				case "VampireBlitz":
					
					// this game is a popup game that includes the start, win, and lose popups in one file
					// create popup and add to scene
					popup = shellApi.sceneManager.currentScene.addChildGroup(new TargetShootingGamePower()) as Popup;
					
					// create campaign data
					data = new CampaignData();
					data.campaignId = "ArcadeVampireBlitz";
					popup.campaignData = data;
					
					// create popup data
					popup.data = new Object();
					popup.data.param1 = "ArcadeVampireBlitz/Game.xml";
					popup.data.swfPath = "ArcadeVampireBlitz/Game.swf";
					
					// initialize popup
					popup.init( shellApi.sceneManager.currentScene.overlayContainer );
					break;
				
				default:
					
					// these are quest games, so load start popup to start game
					var campaignName:String = "Arcade" + gameID + "Quest";
					
					// create ad data
					var ad:AdData = new AdData();
					ad.campaign_name = campaignName;
					ad.campaign_type = AdCampaignType.MAIN_STREET;
					AdManager(shellApi.adManager).interiorAd = ad;
					
					// add popup to scene
					popup = shellApi.sceneManager.currentScene.addChildGroup(new AdStartQuestPopup()) as Popup;
					
					// create campaign data
					data = new CampaignData();
					data.campaignId = campaignName;
					popup.campaignData = data;
					
					// initialize popup
					popup.init(shellApi.sceneManager.currentScene.overlayContainer);
					break;
			}
			
			// play campaign music, if any
			//if (popup.campaignData.musicFile != null)
				//AdManager(shellApi.adManager).playCampaignMusic(popup.campaignData.musicFile);
		}
	}
}