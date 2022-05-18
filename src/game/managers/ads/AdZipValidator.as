package game.managers.ads
{
	import com.poptropica.AppConfig;
	
	import flash.utils.getDefinitionByName;
	
	import engine.Manager;
	import engine.ShellApi;
	import engine.util.Command;
	
	import game.data.ads.AdData;
	import game.data.ads.AdvertisingConstants;
	import game.data.ads.CampaignData;
	import game.data.dlc.DLCContentData;
	import game.managers.ads.AdManager;
	import game.utils.AdUtils;
	
	public class AdZipValidator extends Manager
	{
		/**
		 * Constructor for validating a single ad zip file 
		 * @param shellApi
		 * @param dlcData
		 * @param callback
		 */
		public function AdZipValidator(shellApi:ShellApi, dlcData:DLCContentData, callback:Function)
		{
			_shellApi = shellApi;
			_dlcData = dlcData;
			_campaignName = dlcData.contentId;
			_callback = callback;
			
			// Check that manifest is present locally
			var path:String = "data/" + AdvertisingConstants.AD_PATH_KEYWORD + "/" + _campaignName + AdvertisingConstants.MANIFEST_FILE;
			if (_shellApi.fileManager.verifyFileLocation(path, true) == null)
			{
				// if no manifest found, then jump to end with failure state
				trace("AdValidation: Manifest file not found locally: " + _campaignName);
				doneValidation(false);
			}
			else
			{
				// if manifest found, then load it
				_shellApi.loadFile(path, manifestLoaded);
			}
		}

		/**
		 * Ad asset manifest file loaded
		 * @param manifest
		 */
		private function manifestLoaded(manifest:XML):void
		{
			// if manifest is null, then jump to end with failure state
			if (manifest == null)
			{
				trace("AdValidation: Failure to load ad manifest: " + _campaignName);
				doneValidation(false);
			}
			else
			{
				// if manifest is valid
				// process all ad files in manifest
				processManifest(manifest);
			}
		}
		
		/**
		 * process manifest for validation
		 * @param manifest
		 */
		private function processManifest(manifest:XML):void
		{
			// get array of all files in manifest
			var fileList:Array = AdUtils.getManifestList(manifest);
			_fileLoadCounter = 0;
			var campaignFile:String;
			var versionFile:String;
			var failure:Boolean = false;
			
			// for each file
			for each (var url:String in fileList)
			{
				// make sure file is in local storage
				// if file not found locally, then jump to end with failure state
				if (_shellApi.fileManager.verifyFileLocation(url, true) == null)
				{
					trace("AdValidation: File not found locally: " + _campaignName + " " + url);
					failure = true;
				}
				else if (!failure)
				{
					// if no failure
					// look for possible campaign or version file
					if (url.indexOf(AdvertisingConstants.VERSION_FILE) != -1)
					{
						versionFile = url;
						_fileLoadCounter++;
					}
					else if (url.indexOf(AdvertisingConstants.CAMPAIGN_FILE) != -1)
					{
						campaignFile = url;
						_fileLoadCounter++;
					}
				}
			}
			// if failure, then end with failure state
			if (failure)
			{
				doneValidation(false);
			}
			else if (_fileLoadCounter == 0)
			{
				// if no failure and no campaign or version files, then end with success state
				doneValidation(true);
			}
			else
			{
				// if campaign or version files
				// if version file, then load it
				if (versionFile)
					_shellApi.loadFile(versionFile, Command.create(versionFileLoaded,versionFile));
				// if campaign file, then load it
				if (campaignFile)
					_shellApi.loadFile(campaignFile, Command.create(campaignFileLoaded,campaignFile));
			}
		}
		
		/**
		 * When version.xml is loaded
		 * @param versionXml
		 * @param url
		 */
		private function versionFileLoaded(versionXml:XML, url:String):void
		{
			// check version number in xml against app's version number
			// only need to check first node
			for each (var node:XML in versionXml.children())
			{
				// get version number in form 0.0.0
				var versionNum:String = String(node.valueOf());
				// get app version number (has form "0.0.0")
				// get the part before the first space
				var appVersion:String = AppConfig.appVersionNumber;
				trace("current app version number: " + appVersion);
				// if no app version string, then set to zip version number
				if (appVersion == null)
					appVersion = versionNum;
				trace("AdValidation: comparing version " + versionNum + " against build number " + appVersion);
				var versionArray:Array = versionNum.split(".");
				var compareNum:int = 1000*1000*int(versionArray[0]) + 1000*int(versionArray[1]) + int(versionArray[2]);
				
				// get build number (in form 0.0.0)
				var buildArray:Array = appVersion.split(".");
				var buildNum:int = 1000*1000*int(buildArray[0]) + 1000*int(buildArray[1]) + int(buildArray[2]);
				
				// if current build number is less than version number, then fail validation
				if (buildNum < compareNum)
				{
					trace("AdValidation: fail: current build number is less then version number for ad zip");
					doneValidation(false);
					return;
				}
				else
				{
					// notify that file is loaded
					adFileLoaded((versionXml != null), url);
					return;
				}
			}
		}
		
		/**
		 * When campaign.xml is loaded 
		 * @param campaignXml
		 * @param url
		 */
		private function campaignFileLoaded(campaignXml:XML, url:String):void
		{
			// if not null or empty
			var isValid:Boolean = ((campaignXml != null) && (campaignXml != ""));
			if (isValid)
			{
				// create campaign data object
				var campaignData:CampaignData = new CampaignData( campaignXml );
				// determine campaign ID
				var arr:Array = url.split("/");
				var campaignId:String = arr[arr.length-2];
				campaignData.campaignId = campaignId;
				// add to list of active campaigns
				AdManager(_shellApi.adManager).addActiveCampaign( campaignData );
				trace("AdValidation: campaign data created for: " + campaignId );
			}
			// notify that file is loaded
			adFileLoaded( isValid, url);
		}
		
		/**
		 * Ad file preloaded callback (for campaign.xml and/or classes.xml)
		 * @param hasData Boolean that file has data
		 * @param url
		 */
		private function adFileLoaded( hasData:Boolean, url:String):void
		{
			// if no failure yet
			if (!_adFailure)
			{
				// if no data, then jump to end with failure state
				if (!hasData)
				{ 
					trace("AdValidation: File failed to load: " + _campaignName + " " + url);
					doneValidation(false);
				}
				else
				{
					// if has data
					// increment file counter
					_totalFilesLoaded++;
					trace("AdValidation: File loaded successfully: " + _campaignName + " " + url);
					
					// if all files downloaded, then jump to end with success state
					if (_totalFilesLoaded == _fileLoadCounter)
					{
						doneValidation(true);
					}
				}
			}
			else 
			{
				// if ad failure, then delete currently loaded file (just in case)
				_shellApi.deleteFiles([url]);
			}
		}
		
		/**
		 * Ad zip has completed validation
		 * @param success Boolean
		 * 
		 */
		private function doneValidation(success:Boolean):void
		{
			// FOR TESTING QUESTS
			/*
			if( _dlcData.contentId.indexOf("Quest") != -1 )
			{
				success = false;
			}
			*/
			
			// if successful
			if (success)
			{
				trace("AdValidation: SUCCESS: " + _campaignName);
				// set ad zip as valid
				_shellApi.dlcManager.setContentValid(_campaignName, true);
				
				// add to profile list of campaigns if not already there
				if (_shellApi.profileManager.active.campaigns.indexOf(_campaignName) == -1)
				{
					trace("AdValidation: adding campaign to active profile: " + _campaignName);
					_shellApi.profileManager.active.campaigns.push(_campaignName);
					_shellApi.profileManager.save();
					// get adData
					var adData:AdData = AdManager(_shellApi.adManager).getAdDataByCampaign(_campaignName);
					if (adData != null)
					{
						
					}
				}
			}
			else
			{
				// if failure
				trace("AdValidation: validation FAILED: " + _campaignName);
				_adFailure = true;
				// set ad zip as invalid
				_shellApi.dlcManager.setContentValid(_campaignName, false);
				// remove from campaign list so it won't display
				AdManagerMobile(_shellApi.adManager).deleteCampaign(_campaignName);
			}
			
			// trigger callback and destroy objects
			_callback( _dlcData );
			destroyThis();
		}
		
		/**
		 * Destroy objects 
		 */
		private function destroyThis():void
		{
			_shellApi = null;
			_callback = null;
			_dlcData = null;
		}
		
		private var _shellApi:ShellApi;
		private var _callback:Function;
		private var _dlcData:DLCContentData;
		private var _campaignName:String;
		private var _adFailure:Boolean = false;
		private var _fileLoadCounter:int;
		private var _totalFilesLoaded:int = 0;
	}
}

