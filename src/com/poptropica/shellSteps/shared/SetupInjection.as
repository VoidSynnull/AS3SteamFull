package com.poptropica.shellSteps.shared
{
	import flash.display.Stage;
	
	import engine.ShellApi;
	
	import org.swiftsuspenders.Injector;

	/**
	 * Setup injection so that the ShellApi can be made available to all classes
	 * 
	 * Creates ShellApi & Engine and makes them available through injection.
	 * Establish reference to LSO.
	 * Restores profiles from LSO.
	 * Create manager to handle Groups.
	 * Create scene containers and adjusts sizes base on platform/device.

	 */
	public class SetupInjection extends ShellStep
	{
		// creation of fileManager, injector, shellApi, & managers
		public function SetupInjection()
		{
			super();
		}
		
		override protected function build():void
		{	
			// prepare ShellApi injection
			shellApi.injector = new Injector();
			shellApi.injector.map(Injector).toValue(shellApi.injector);
			shellApi.injector.injectInto(shellApi);
			shellApi.injector.map(ShellApi).toValue(shellApi);
			shellApi.injector.map(Stage).toValue(this.shell.stage);
			
			built();
		}
	}
}