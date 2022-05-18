package com.poptropica.shells
{
	import com.poptropica.shellSteps.shared.DetermineQualityLevel;
	import com.poptropica.shellSteps.shared.ConfigureGame;
	import com.poptropica.shellSteps.shared.CreateCoreManagers;
	import com.poptropica.shellSteps.shared.FileIO;
	import com.poptropica.shellSteps.shared.GetFirstScene;
	import com.poptropica.shellSteps.shared.LongTermMemoryRestore;
	import com.poptropica.shellSteps.shared.SetPlatform;
	import com.poptropica.shellSteps.shared.SetupInjection;
	import com.poptropica.shellSteps.shared.SetupManifestCheck;
	import com.poptropica.shellSteps.shared.StartGame;
	import com.poptropica.shells.shared.steps.CreateConnectionPop;
	import com.poptropica.shells.shared.steps.CreateGamePop;
	import com.poptropica.shells.shared.steps.SetupCampaigns;
	
	public class DesktopShell extends Shell
	{
		public function DesktopShell()
		{
			super();
		}
		
		override protected function construct():void
		{
			this.addStep(new SetupInjection());			// Setup injection for ShellApi so subsequent classes can access ShellApi via injection
			this.addStep(new SetPlatform());			// Set platform specific flags, assign platform class implementing IPlatform
			this.addStep(new CreateCoreManagers());		// Create essential core managers
			this.addStep(new LongTermMemoryRestore());	// Retrieve long term memory from LSO, restore stored profile data
			this.addStep(new DetermineQualityLevel());  // Set quality level based on user override or platform.
			this.addStep(new FileIO());					// Create file loading facilities
			this.addStep(new SetupManifestCheck());		// FOR DEBUG : setup manifest verification if AppConfig.verifyPathInManifest == true
			this.addStep(new CreateConnectionPop());	// Used if you need to connect to server
			this.addStep(new ConfigureGame());			// Load game configuration (game.xml) and apply settings appropriately
			this.addStep(new SetupCampaigns());			// Setup advertising if active 
			this.addStep(new CreateGamePop());			// Create game specific managers, along with anything Poptropica specific
			this.addStep(new GetFirstScene());			// Determine first scene
			this.addStep(new StartGame());				// start tick update, load first scene
			this.build();
		}
	}
}