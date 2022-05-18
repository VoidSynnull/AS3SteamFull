package com.poptropica.shells.mobile.steps
{
	import com.poptropica.AppConfig;
	
	import game.data.dlc.DLCContentData;
	import game.managers.DLCManager;
	
	import org.assetloader.signals.ProgressSignal;

	public class MobileStepInstallHomeFiles extends ShellStep
	{
		public function MobileStepInstallHomeFiles()
		{
			super();
			stepDescription = "Installing Files";
		}
		
		override protected function build():void
		{
			if( AppConfig.ignoreDLC )
			{
				super.built();
			}
			else
			{
				// File IO & DLC must be setup prior to this step
				this.loadStartUpContent();
			}
		}

		//////////////////////////////////////////// LOAD START CONTENT ////////////////////////////////////////////
				
		private function loadStartUpContent():void
		{
			var contentId:String = "";
			var dlcManager:DLCManager = shellApi.getManager(DLCManager) as DLCManager;
			while( homeFiles.length > 0 )
			{
				contentId = homeFiles.pop();
				
				// Forcing start content to reinstall if app has updated, this is to attempt a fix for missing start assets
				if( AppConfig.appUpdated )
				{
					trace(this," :: loadStartUpContent : forcing install for content: " + contentId);
					dlcManager.forceContentInstall(contentId);
				}
				
				if( !dlcManager.isInstalled(contentId) )
				{
					loadNextContent( contentId );
					return;
				}
			}
			
			trace("IosShell :: all home/shared content unzipped");
			this.built();
		}
		
		private function loadNextContent( contentId:String ) : void
		{
			shellApi.dlcManager.loadContentById( contentId, loadStartUpContent, onContentProgress, onContentError );
		}
		
		private function onContentProgress(progress:ProgressSignal):void
		{
			// TODO :: May want to do something with this progress
			//this._currentButton.get(Display).displayObject["progress"].scaleX = progress.progress / 100;
		}

		private function onContentError( dlcContent:DLCContentData ):void
		{
			trace(this," :: ERROR :: error with content.");
		}

		private var homeFiles:Array = ["start"];
		protected const INSTALL_HOME_FILES:String				= "installHomeFiles";
		protected const REMOVE_INACTIVE_CAMPAIGN_FILES:String   = "removeInactiveCampaignFiles";
	}
}