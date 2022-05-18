package com.poptropica.shellSteps.shared
{
	import game.data.ads.AdvertisingConstants;
	import game.managers.ProfileManager;
	import game.managers.SceneManager;
	import game.util.ClassUtils;
	import game.util.DataUtils;

	public class GetFirstScene extends ShellStep
	{
		// starts frame tick and loads first scene
		public function GetFirstScene()
		{
			super();
		}
		
		override protected function build():void
		{			
			checkActiveScene();
			built();
		}
		
		/**
		 * Checks for edge cases regarding initial scene.
		 * If edges cases not detected, active Profile's scene remains the initial scene.
		 */
		protected function checkActiveScene():void
		{
			var profileManager:ProfileManager = ProfileManager(this.shellApi.getManager(ProfileManager));
			var sceneManager:SceneManager = SceneManager(this.shellApi.getManager(SceneManager));
			
			// overrideScene used for testing or 'standalone' builds that should automatically launch a minigame.
			if ( DataUtils.validString(sceneManager.gameData.overrideScene) ) 
			{
				trace("GetFirstScene Step :: gamedata overrides scene", profileManager.active.scene, 'with', sceneManager.gameData.overrideScene);
				profileManager.active.scene = sceneManager.gameData.overrideScene;
				checkActiveSceneValid();
				profileManager.save();
			} 
			else 
			{
				if( !checkActiveSceneValid() )
				{
					profileManager.save();	// if active scene reverted to default save change to profile
				}					
			}
		}
		
		/**
		 * Checks if current scene is valid, if not falls back to default and saves change to ProfileManager
		 */
		protected function checkActiveSceneValid():Boolean
		{
			var profileManager:ProfileManager = ProfileManager(this.shellApi.getManager(ProfileManager));
			var sceneManager:SceneManager = SceneManager(this.shellApi.getManager(SceneManager));

			// if current scene String is not valid fall back to default
			// QUESTION :: Why would it have a "." in it? - bard
			if ( !DataUtils.validString(profileManager.active.scene) || (profileManager.active.scene.indexOf('.') < 0)) 
			{
				trace("GetFirstScene Step :: active scene string is not valid: " + profileManager.active.scene );
				trace("GetFirstScene Step :: reverting to default scene: " + sceneManager.gameData.defaultScene);
				// TODO :: Probably want to reset last positions as well?
				profileManager.active.scene = sceneManager.gameData.defaultScene;
				return false;
			}
			else
			{
				// check if scene string relates to a valid Class
				// RLH: strip off any ad related addtions for strings such as game.scenes.custom.questInterior.QuestInterior|campaignScene=GalacticHotDogsQuest_Interior
				var scene:String = profileManager.active.scene.split(AdvertisingConstants.CAMPAIGN_SCENE_DELIMITER)[0];
				var sceneClass:Class = ClassUtils.getClassByName(scene);
				
				if(!sceneClass)
				{
					trace("ERROR :: GetFirstScene Step :: profile's active scene does not relate to a valid class: " + scene );
					trace("GetFirstScene Step : reverting to default scene: " + sceneManager.gameData.defaultScene);
					profileManager.active.scene = sceneManager.gameData.defaultScene;
					return false;
				}
			}
			
			return true;
		}
	}
}