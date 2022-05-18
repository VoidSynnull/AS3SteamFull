package com.poptropica.shells.photoBooth
{
	import com.poptropica.shellSteps.mobile.MobileStepFileIO;
	import com.poptropica.shellSteps.shared.*;
	import com.poptropica.shells.mobile.MobileShell;
	import com.poptropica.shells.mobile.android.steps.AndroidStepSetPlatform;
	import com.poptropica.shells.photoBooth.steps.CreatePhotoBooth;
	import com.poptropica.shells.photoBooth.steps.PhotoBoothConfigureGame;
	import com.poptropica.shells.shared.steps.CreateConnectionPop;
	import com.poptropica.shells.shared.steps.SetupCampaigns;
	
	public class PhotoBoothShell extends MobileShell
	{
		public function PhotoBoothShell()
		{
			super();
		}
		
		override protected function construct():void
		{
			this.addStep(new SetupInjection());			// Setup injection for ShellApi so subsequent classes can access ShellApi via injection
			this.addStep(new AndroidStepSetPlatform());			// Set platform specific flags, assign platform class implementing IPlatform
			this.addStep(new CreateCoreManagers());		// Create essential core managers
			this.addStep(new LongTermMemoryRestore());	// Retrieve long term memory from LSO, restore stored profile data
			this.addStep(new DetermineQualityLevel());  // Set quality level based on user override or platform.
			this.addStep(new MobileStepFileIO());					// Create file loading facilities
			this.addStep(new SetupManifestCheck());		// FOR DEBUG : setup manifest verification if AppConfig.verifyPathInManifest == true
			this.addStep(new CreateConnectionPop());	// Used if you need to connect to server
			this.addStep(new PhotoBoothConfigureGame());			// Load game configuration (game.xml) and apply settings appropriately
			this.addStep(new CreatePhotoBooth());			// Create game specific managers, along with anything Poptropica specific
			this.addStep(new GetFirstScene());
			this.addStep(new SetupCampaigns());			// Setup advertising if active // Determine first scene
			this.addStep(new StartGame());				// start tick update, load first scene
			this.build();
		}
	}
}