package com.poptropica.shells.mobile
{
	import com.poptropica.shellSteps.mobile.MobileAppVersionCheck;
	import com.poptropica.shellSteps.mobile.MobileStepFileIO;
	import com.poptropica.shellSteps.mobile.MobileStepSetupIslandDLC;
	import com.poptropica.shellSteps.mobile.MobileStepStartGame;
	import com.poptropica.shellSteps.shared.ConfigureGame;
	import com.poptropica.shellSteps.shared.CreateCoreManagers;
	import com.poptropica.shellSteps.shared.DetermineQualityLevel;
	import com.poptropica.shellSteps.shared.GetFirstScene;
	import com.poptropica.shellSteps.shared.LongTermMemoryRestore;
	import com.poptropica.shellSteps.shared.SetActiveProfile;
	import com.poptropica.shellSteps.shared.SetupErrorHandling;
	import com.poptropica.shellSteps.shared.SetupManifestCheck;
	import com.poptropica.shells.browser.steps.BrowserGetUserPrefs;
	import com.poptropica.shells.browser.steps.BrowserStepGetFirstScene;
	import com.poptropica.shells.browser.steps.BrowserStepGetMemberStatus;
	import com.poptropica.shells.browser.steps.BrowserStepGetPlayerData;
	import com.poptropica.shells.mobile.steps.MobileStepGetStoreCards;
	import com.poptropica.shells.browser.steps.BrowserStepRestoreGlobalItems;
	import com.poptropica.shells.mobile.steps.CreateMobileTracker;
	import com.poptropica.shells.mobile.steps.KeepDeviceAwake;
	import com.poptropica.shells.mobile.steps.MobileStepCreateConnection;
	import com.poptropica.shells.mobile.steps.MobileStepCreateGame;
	import com.poptropica.shells.mobile.steps.MobileStepInstallHomeFiles;
	import com.poptropica.shells.mobile.steps.MobileStepSetupCampaigns;
	import com.poptropica.shells.mobile.steps.MobileStepShowSplashScreen;
	import com.poptropica.shells.mobile.steps.ResumeDeviceIdle;
	import com.poptropica.shells.shared.steps.CreatePartKeys;
	
	public class MobileShell extends Shell
	{
		public function MobileShell()
		{
			super();
		}
		
		override protected function construct():void
		{
			addStep(new KeepDeviceAwake());
			addStep(new SetupErrorHandling());				// Sets up uncaught error listener and error tracking
			addStep(new CreateCoreManagers());				// Create essential core managers
			addStep(new MobileStepShowSplashScreen());
			addStep(new LongTermMemoryRestore());			// Retrieve long term memory from LSO, restore stored profile data
			addStep(new MobileAppVersionCheck());			// Store current version of app if it is a new version and do any update operations if so.
			addStep(new DetermineQualityLevel());  			// Set quality level based on user override or platform.
			addStep(new MobileStepFileIO());				// Create file loading facilities & move global files from app to storage
			addStep(new MobileStepCreateConnection());		// Establish to connection to server
			addStep(new MobileStepSetupIslandDLC());		// add DLC manager & load and parse island dlc definitions & zipchecksums 
			addStep(new SetupManifestCheck());				// FOR DEBUG : Adds a class to FileManager that checks files agianst asset manifests
			addStep(new MobileStepInstallHomeFiles());		// Installs initial content TODO :: Break this up, possibly check for complete later in build process
			addStep(new CreatePartKeys());					// Create frame > label part key, for converting part values coming from AS2
			addStep(new SetActiveProfile());				// Determines the active profile, not entirely necessary for mobile
			addStep(new ConfigureGame());
			addStep(new MobileStepSetupCampaigns());		// Setup advertising 
			addStep(new MobileStepCreateGame());			// IslandManager, shared managers, dev tools, native app methods
			addStep(new CreateMobileTracker());
			//addStep(new RestoreGlobalItems());
			addStep(new MobileStepGetStoreCards());
			addStep(new GetFirstScene());
			addStep(new MobileStepStartGame());
			addStep(new ResumeDeviceIdle());
			build();
		}
		
		override protected function constructPostProcessBuildSteps():void
		{
			addStep(new KeepDeviceAwake());
			addStep(new BrowserStepGetMemberStatus());		// Determine membership status from external sources
			addStep(new BrowserStepRestoreGlobalItems());
			addStep(new BrowserStepGetPlayerData());		// Retrieves & applies look and character name from server to active Profile
			addStep(new BrowserGetUserPrefs(true));			// Retrieve stored values for settings panel from the data storage
			addStep(new BrowserStepGetFirstScene(true));	// Determine first scene for user (initializingLogin is set to true)\
			addStep(new ResumeDeviceIdle());
		}
	}
}