package com.poptropica.shells.browser.steps
{
	import com.poptropica.AppConfig;
	
	import engine.managers.SoundManager;
	
	import game.data.comm.PopResponse;
	import game.managers.ProfileManager;
	import game.proxy.DataStoreRequest;
	import game.proxy.GatewayConstants;
	import game.proxy.IDataStore2;
	import game.util.PerformanceUtils;
	
	public class BrowserGetUserPrefs extends ShellStep
	{
		protected var initializingLogin:Boolean = false;
		//// CONSTRUCTOR ////
	
		public function BrowserGetUserPrefs(initializingLogin:Boolean)
		{
			super();
			this.initializingLogin = initializingLogin;
			stepDescription = "Setting user preferences";
		}
	
		//// PROTECTED METHODS ////
	
		protected override function build():void
		{
			if (shellApi.profileManager.active.isGuest) {
				built();
			} else {
				var req:DataStoreRequest = DataStoreRequest.settingsRetrievalRequest();
				req.requestTimeoutMillis = 1000;
				//shellApi.siteProxy.retrieve(DataStoreRequest.settingsRetrievalRequest(), onSettingsPanelPrefs);
				(shellApi.siteProxy as IDataStore2).call(req, onSettingsPanelPrefs);
			}
		}
	
		/**
		 * Handler called after requesting settings panel data from server, if found data is applied to ProfileManager.
		 * If response fails, defaults settings remain.
		 * @param result - PopResponse from server, if success contains data for settings panel
		 * 
		 * Example server response:
		 * {status:7, error:"", data:fields":{"dialogSpeed":"1","musicVolume":"0.049758367639162","language":"en_us","effectsVolume":"0.41131197422588"},"error":null} 
		 */
		private function onSettingsPanelPrefs(result:PopResponse):void 
		{
			//trace("The Settings Panel Prefs!", result.toString());
			if (result) 
			{
				if (GatewayConstants.AMFPHP_NODATA == result.status) {
					//trace('db has no stored prefs, best go with app defaults');
				} else if (!result.succeeded) {
					//trace('gateway problem, best go with app defaults');
				} else {
					if(result.data != null && result.data.fields!= null )
					{
						var profileManager:ProfileManager = shellApi.profileManager;
						
						if (result.data.fields.musicVolume) {
							profileManager.active.musicVolume = result.data.fields.musicVolume;
							profileManager.active.ambientVolume	= result.data.fields.musicVolume;
						}
						if (result.data.fields.effectsVolume) {
							profileManager.active.effectsVolume	= result.data.fields.effectsVolume;
						}
						if (result.data.fields.dialogSpeed) {
							profileManager.active.dialogSpeed = result.data.fields.dialogSpeed;
						}
						else{
							profileManager.setDialogSpeedByAge();
						}
						if (result.data.fields.qualityLevel) {	
							// NOTE :: Don't love doing this twice (already hapens in DetermineQualityLevel), can look into better approach in future. -bard
							if( !isNaN(Number(result.data.fields.qualityLevel)) && Number(result.data.fields.qualityLevel) > -1 )
							{
								profileManager.active.qualityOverride = Math.max(AppConfig.minimumQuality, Number(result.data.fields.qualityLevel));
								PerformanceUtils.qualityLevel = profileManager.active.qualityOverride;
								PerformanceUtils.determineAndSetVectorQuality();
								PerformanceUtils.determineAndSetDefaultBitmapQuality();
							}
						}
						if (result.data.fields.language) {
							profileManager.active.preferredLanguage	= result.data.fields.language;
							//profileManager.active.preferredLanguage	= ProfileManager.languageCodeForLanguageTag(result.data.fields.language);
						}
						profileManager.save();
					}
				}
			}
			
			// get muted settings
			if (initializingLogin)
			{
				SoundManager(shellApi.getManager(SoundManager)).getMutedSetting();
			}

			built();
		}
	}
}
