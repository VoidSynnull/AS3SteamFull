package com.poptropica.shellSteps.mobile
{
	import com.poptropica.shellSteps.shared.StartGame;
	
	import game.managers.ProfileManager;
	import game.managers.SceneManager;
	import game.managers.interfaces.IIslandManager;
	import game.util.ClassUtils;

	public class MobileStepStartGame extends StartGame
	{
		public function MobileStepStartGame()
		{
			super();
		}
		
		override protected function build():void
		{
			this.shell._tickProvider.start();
			this.loadFirstScene();
			built();
		}

		override protected function loadFirstScene():void
		{
			var profileManager:ProfileManager = ProfileManager(this.shellApi.getManager(ProfileManager));
			var sceneManager:SceneManager = SceneManager(this.shellApi.getManager(SceneManager));
			
			
			//regardless of active scene, we always start with first scene specified by game config
			trace( "MobileStepStartGame :: loading first scene: " + sceneManager.gameData.firstScene );
			var sceneClass:Class = ClassUtils.getClassByName(sceneManager.gameData.firstScene);
			// NOTE :: Since the first scene doesn't load the player, no need to pass in player specific parameters to loadScene
			IIslandManager(this.shellApi.getManager(IIslandManager)).loadScene(sceneClass);
		}
	}
}