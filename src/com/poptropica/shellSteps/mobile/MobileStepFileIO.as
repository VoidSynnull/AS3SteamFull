package com.poptropica.shellSteps.mobile
{
	import com.poptropica.AppConfig;
	import com.poptropica.interfaces.INativeFileMethods;
	import com.poptropica.shellSteps.shared.FileIO;
	
	import flash.utils.Dictionary;
	
	import engine.managers.FileManager;

	public class MobileStepFileIO extends FileIO
	{
		public function MobileStepFileIO()
		{
			super();
			stepDescription = "Preparing file system";
		}
		
		override protected function build():void
		{
			// add file manager
			var fileManager:FileManager = createFileManager();
			
			if( !AppConfig.ignoreDLC )
			{
				fileManager.nativeMethods = shellApi.platform.getInstance(INativeFileMethods) as INativeFileMethods;
				// creates a folder for files downloaded from the web if it doesn't exist.
				// if new version of app removes the current downloads folder and create new one 
				// this allows for updated assets to replace the current ones.
				fileManager.nativeMethods.createDownloadsFolder(AppConfig.appUpdated);
				fileManager.stoppableLoaders = new Dictionary(true);
			}

			this.built();
		}
	}
}