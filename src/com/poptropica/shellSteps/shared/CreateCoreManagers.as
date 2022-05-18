package com.poptropica.shellSteps.shared
{
	import com.poptropica.AppConfig;
	
	import ash.core.Engine;
	
	import engine.managers.GroupManager;
	
	import game.managers.ScreenManager;

	/**
	 * Build creates managers essential to core functionality.
	 * 
	 * Creates ShellApi & Engine and makes them available through injection.
	 * Establish reference to LSO.
	 * Restores profiles from LSO.
	 * Create manager to handle Groups.
	 * Create scene containers and adjusts sizes base on platform/device.
	 * 
	 * This is generally step #2 in the build steps. 
	 */
	public class CreateCoreManagers extends ShellStep
	{
		// creation of fileManager, injector, shellApi, & managers
		public function CreateCoreManagers()
		{
			super();
		}
		
		override protected function build():void
		{				
			// set application url from loaderInfo
			AppConfig.applicationUrl = "https://";
			trace( "ShellStep : CreateCoreManagers : appplication url is: " + "https://" );
			
			// create & inject Engine
			var systemManager:Engine = new Engine();
			shellApi.injector.map(Engine).toValue(systemManager);
			
			// create & inject GroupManager
			var groupManager:GroupManager = GroupManager(this.shellApi.addManager(new GroupManager(systemManager)));
			shellApi.injector.map(GroupManager).toValue(groupManager);
			
			// create & inject ScreenManager
			// creates screen container and determines dimensions on construct
			var screenManager:ScreenManager = ScreenManager(this.shellApi.addManager(new ScreenManager(this.shell.stage)));
			shellApi.injector.map(ScreenManager).toValue(screenManager);
			
			built();
		}
	}
}