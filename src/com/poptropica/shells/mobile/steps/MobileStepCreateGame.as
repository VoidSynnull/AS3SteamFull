package com.poptropica.shells.mobile.steps
{
	import com.poptropica.AppConfig;
	import com.poptropica.shells.shared.steps.CreateGamePop;
	
	import game.managers.interfaces.IIslandManager;
	import game.managers.mobile.IslandManagerMobile;
	import game.scene.template.DoorGroupPop;
	import game.ui.hud.HudPopMobile;
	
	public class MobileStepCreateGame extends CreateGamePop
	{
		public function MobileStepCreateGame()
		{
			super();
			stepDescription = "Creating game components";
		}
		
		override protected function build():void
		{
			// add managers specific to mobile
			if( !AppConfig.ignoreDLC )
			{
				var islandManager:IslandManagerMobile = this.shellApi.addManager(new IslandManagerMobile(), IIslandManager) as IslandManagerMobile;
				islandManager.gameData = shellApi.sceneManager.gameData;
				islandManager.hudGroupClass = HudPopMobile;
				islandManager.doorGroupClass = DoorGroupPop;
			}

			// add standard game managers that are shared across platforms IF we don't override them here.
			super.addManagers();
			
			// don't create dev tools for production 
			/*if( !AppConfig.production )
			{
				super.createDevTools();
			}*/
			//Create dev tools regardless of build type. Debug can be unlocked in production builds now.
			super.createDevTools();

			shellApi.setupNativeAppMethods();
			
			built();
		}
	}
}