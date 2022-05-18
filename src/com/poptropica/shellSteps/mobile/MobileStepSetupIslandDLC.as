package com.poptropica.shellSteps.mobile
{
	import com.poptropica.AppConfig;
	
	import engine.managers.FileManager;
	
	import game.managers.DLCManager;

	public class MobileStepSetupIslandDLC extends ShellStep
	{
		public function MobileStepSetupIslandDLC()
		{
			super();
			stepDescription = "Setting up downloadable content";
		}
		
		override protected function build():void
		{
			if( !AppConfig.ignoreDLC )
			{
				// add DLC manager
				var dlcManager:DLCManager = new DLCManager();
				shellApi.addManager(dlcManager);
				
				// Ensures the island dlc files are loaded from app directory to app storage directory.
				// NOTE :: These files are not listed in zips, so we need to be sure to assign them here
				var fileManager:FileManager = shellApi.fileManager as FileManager;
				fileManager.copyFileToStorage(islandDLCPath);
				fileManager.copyFileToStorage(islandCheckSumPath);
				
				// Have DLCManager load and parse files that define island content and their zipchecksums ;
				dlcManager.loadIslandDLCData(islandDLCPath, islandCheckSumPath, super.built );
			}
			else
			{
				super.built();
			}
		}
		
		protected var islandDLCPath:String = "data/dlc/islands.xml";
		protected var islandCheckSumPath:String = "data/dlc/zipCheckSums.xml";
	}
}