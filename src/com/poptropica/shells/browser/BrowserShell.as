package com.poptropica.shells.browser
{
	import com.poptropica.shellSteps.browser.BrowserStepFileIO;
	import com.poptropica.shellSteps.browser.BrowserStepSetPlatform;
	import com.poptropica.shellSteps.shared.ConfigureGame;
	import com.poptropica.shellSteps.shared.CreateCoreManagers;
	import com.poptropica.shellSteps.shared.DetermineQualityLevel;
	import com.poptropica.shellSteps.shared.LongTermMemoryRestore;
	import com.poptropica.shellSteps.shared.SetupErrorHandling;
	import com.poptropica.shellSteps.shared.SetupInjection;
	import com.poptropica.shellSteps.shared.SetupManifestCheck;
	import com.poptropica.shells.browser.steps.BrowserGetUserPrefs;
	import com.poptropica.shells.browser.steps.BrowserStepCreateConnection;
	import com.poptropica.shells.browser.steps.BrowserStepCreateGame;
	import com.poptropica.shells.browser.steps.BrowserStepGetFirstScene;
	import com.poptropica.shells.browser.steps.BrowserStepGetMemberStatus;
	import com.poptropica.shells.browser.steps.BrowserStepGetPlayerData;
	import com.poptropica.shells.browser.steps.BrowserStepGetStoreCards;
	import com.poptropica.shells.browser.steps.BrowserStepGetTribeFromServer;
	import com.poptropica.shells.browser.steps.BrowserStepRestoreGlobalItems;
	import com.poptropica.shells.browser.steps.BrowserStepSetActiveProfile;
	import com.poptropica.shells.browser.steps.BrowserStepSetupCampaigns;
	import com.poptropica.shells.browser.steps.BrowserStepStartGame;
	import com.poptropica.shells.browser.steps.BrowserStepSyncProfileFromLSO;
	import com.poptropica.shells.browser.steps.CreateBrowserTracker;
	import com.poptropica.shells.shared.steps.CreatePartKeys;
	
	public class BrowserShell extends Shell
	{
		public function BrowserShell()
		{
			super();
		}
		
		override protected function construct():void
		{
			//this.addStep(new BrowserStepShowSplashScreen());
			this.addStep(new SetupErrorHandling());				// Sets up uncaught error listener and error tracking
			this.addStep(new SetupInjection());					// Setup injection for ShellApi so subsequent classes can access ShellApi via injection
			this.addStep(new BrowserStepSetPlatform());			// Set platform specific flags, assign platform class implementing IPlatform
			this.addStep(new CreateCoreManagers());				// Create essential core managers
			this.addStep(new LongTermMemoryRestore());			// Retrieve long term memory from LSO, restore stored profile data
			this.addStep(new BrowserStepFileIO());				// Create file loading facilities
			this.addStep(new SetupManifestCheck());				// FOR DEBUG : setup manifest verification if AppConfig.verifyPathInManifest == true
			this.addStep(new BrowserStepCreateConnection());	// load communication configuration (comm.xml) and apply settings appropriately, establish connection to host
			this.addStep(new ConfigureGame());					// load game configuration (game.xml) and apply settings appropriately
			this.addStep(new BrowserStepSetupCampaigns());		// Setup advertising
			this.addStep(new BrowserStepSetActiveProfile());	// determine active user, in case of browser refer to as2LSO for user status and access
			this.addStep(new DetermineQualityLevel());  		// Set quality level based on user override or platform.
			this.addStep(new CreatePartKeys());					// Create frame > label part key, for converting part values coming from AS2
			this.addStep(new BrowserStepSyncProfileFromLSO());	// Apply data from as2LSO to profile	
			this.addStep(new BrowserStepGetMemberStatus());		// Determine membership status from external sources
			this.addStep(new BrowserStepCreateGame());			// Create game specific managers, in case of browser check LoaderInfo for override scene
			this.addStep(new BrowserStepGetPlayerData());		// Retrieves & applies look and character name from server to active Profile	
			this.addStep(new BrowserStepGetStoreCards());		// Retrieves store cards from server	
			this.addStep(new CreateBrowserTracker());			// Create Tracker
			this.addStep(new BrowserStepRestoreGlobalItems());	// Retrieve global items (store,custom) from external sources (server,asLSO) and apply to ItemManager
			this.addStep(new BrowserStepGetTribeFromServer());	// Retrieve tribe user field from external sources (server,asLSO) and apply to profile
			this.addStep(new BrowserGetUserPrefs(false));		// Retrieve stored values for settings panel from the data storage
			this.addStep(new BrowserStepGetFirstScene(false));	// Determine first scene (initializingLogin is set to false)
			this.addStep(new BrowserStepStartGame());			// start tick update, load first scene
			
			build();
		}
		
		override protected function constructPostProcessBuildSteps():void
		{
			//this.addStep(new BrowserStepSetActiveProfile());	// determine active user, in case of browser refer to as2LSO for user status and access
			this.addStep(new BrowserStepGetMemberStatus());		// Determine membership status from external sources
			this.addStep(new BrowserStepRestoreGlobalItems());
			this.addStep(new BrowserStepGetPlayerData());		// Retrieves & applies look and character name from server to active Profile
			this.addStep(new BrowserGetUserPrefs(true));		// Retrieve stored values for settings panel from the data storage
			this.addStep(new BrowserStepGetFirstScene(true));	// Determine first scene for user (initializingLogin is set to true)
		}
	}
}