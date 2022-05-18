package com.poptropica.shellSteps.shared
{
	import com.poptropica.AppConfig;
	
	import game.data.ads.AdvertisingConstants;
	import game.managers.ProfileManager;
	import game.managers.interfaces.IIslandManager;
	import game.util.ClassUtils;
	

	public class StartGame extends ShellStep
	{
		public function StartGame()
		{
			super();
		}
		
		override protected function build():void
		{
			this.shell._tickProvider.start();	// TODO :: could use comments regarding _tickProvider
			loadFirstScene();
			built();
		}
		
		/**
		 * For override 
		 */
		protected function loadFirstScene():void
		{
			var islandManager:IIslandManager = this.shellApi.getManager(IIslandManager) as IIslandManager;
			var profileManager:ProfileManager = ProfileManager(this.shellApi.getManager(ProfileManager));
			
			// QUESTION :: in what scenario would we want autoLoadFirstScene to be false? - bard

			if( AppConfig.debug && !islandManager.gameData.autoLoadFirstScene)
			{
				// Do nothing?  This would be used for debug purposes
			}
			else
			{
				// RLH: strip off campaign related additons for strings such as game.scenes.custom.questInterior.QuestInterior|campaignScene=GalacticHotDogsQuest_Interior
				var scene:String = profileManager.active.scene.split(AdvertisingConstants.CAMPAIGN_SCENE_DELIMITER)[0];
				var sceneClass:Class = ClassUtils.getClassByName(scene);
				islandManager.loadScene(sceneClass, profileManager.active.lastX, profileManager.active.lastY, profileManager.active.lastDirection);
			}
		}
	}
}