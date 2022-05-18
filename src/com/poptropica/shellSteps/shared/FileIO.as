package com.poptropica.shellSteps.shared
{
	import com.poptropica.AppConfig;
	
	import engine.managers.FileManager;
	
	import game.util.ProxyUtils;

	/**
	 * Build step that sets up storage managers.
	 * Inlcuding file loading, long term storage, profile, etc.
	 * This is generally step #2 in the build steps. 
	 * @author umckiba
	 */
	public class FileIO extends ShellStep
	{
		// creation of fileManager, injector, shellApi, & managers
		public function FileIO()
		{
			super();
		}
		
		override protected function build():void
		{	
			createFileManager();
			this.built();
		}

		protected function createFileManager():FileManager
		{			
			var fileManager:FileManager = FileManager(this.shellApi.addManager(new FileManager()));
			fileManager.contentPrefix = getContentPrefix();
			fileManager.assetPrefix = fileManager.contentPrefix + "assets/";
			fileManager.dataPrefix = fileManager.contentPrefix + "data/";
			fileManager.ioError.add(handleIOError);
			return fileManager;
		}
		
		protected function getContentPrefix():String
		{
			return "";
		}
		
		//////////////////////////////////////// DEBUG METHODS ////////////////////////////////////////
		
		protected function handleIOError(file:String = "", message:String = ""):void
		{
			shellApi.track("MissingAsset", file, message);
			
			trace("FileManager :: IO Error : "+ file + " : " + message);
			
//			if(ProxyUtils.isTestServer(this.shell.loaderInfo.url) && AppConfig.debug)
//			{
//				shellApi.logError(file + " : " + message);
//			}
			if (AppConfig.debug) {
				if (ProxyUtils.isTestServer(shell.loaderInfo.url)) {
					if (!AppConfig.suppressLoadErrorMessages) {
						shellApi.logError(file + " : " + message);
					}
				}
			}
		}
	}
}
