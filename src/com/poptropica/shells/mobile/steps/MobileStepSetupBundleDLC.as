package com.poptropica.shells.mobile.steps
{
	import engine.managers.FileManager;
	
	import game.managers.BundleManager;

	public class MobileStepSetupBundleDLC extends ShellStep
	{
		public function MobileStepSetupBundleDLC() 
		{
			super();
		}
		
		override protected function build():void
		{
			// add Bundles manager
			var bundlesManager:BundleManager = new BundleManager();
			this.shellApi.addManager( bundlesManager );
			
			// Ensures the bundle dlc files are loaded from app directory to app storage directory.
			// NOTE :: These files are not listed in zips, so we need to be sure to assign them here
			var fileManager:FileManager = shellApi.fileManager as FileManager;
			fileManager.copyFileToStorage(bundleDLCPath);
			fileManager.copyFileToStorage(bundleCheckSumPath);
			
			// Have BundleManager load and parse files that define bundle content and their zipchecksums via DLCManager 
			bundlesManager.setup( super.built );
		}
		
		protected var bundleDLCPath:String = "data/dlc/bundles/bundles.xml";
		protected var bundleCheckSumPath:String = "data/dlc/bundles/zipCheckSums.xml";
	}
}