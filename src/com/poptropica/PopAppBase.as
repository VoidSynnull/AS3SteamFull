package com.poptropica {

import flash.display.Sprite;

[SWF(frameRate='60', backgroundColor='#000000')]

/**
 * PopAppBase is an abstract superclass
 * @author	Rich Martin
 */
public class PopAppBase extends Sprite {

	public static const assetHostTest:String		= "https://www.poptropica.com/game/";
	public static const assetHostPrd:String			= "https://www.poptropica.com/game/";
	public static const allowOverwrite:Boolean		= false;
	public static const appVersionNumber:String		= "2.0.0";
	public static const kernelVersionNumber:String	= "2.0.0";
	public static const appBuildInfo:String			= "2.0.0";
	public static const isProductionBuild:Boolean	= true;
	public static const isDebugBuild:Boolean		= false;
	public static const iapOn:Boolean				= false;

	// AD SPECIFIC
	public static const isAdsActive:Boolean			= false;

	public function PopAppBase()
	{
		super();
	}

	////////////////////////////// PRE-BUILD //////////////////////////////

	/**
	 * The <code>preBuild</code> method performs configuration tasks
	 * which must take place before the <code>Shell</code> begins its startup sequence.
	 */
	protected function preBuild():void
	{
		if( allowOverwrite )
		{
			updateDebugFlag();
			updateAdsActiveFlag();
			writeProductionFlag();
		}
		// set versioning regardless, since it doesn't really get set anywhere else
		setVersioning();
		// set asset host
		updateAssetHost();
	}
	
	protected function writeProductionFlag():void
	{
		trace(this," ::writeProductionFlag() sets PlatformUtils.production to", isProductionBuild);
		AppConfig.production = true;
	}

	private function setVersioning():void
	{
		trace("setVersioning appVersionNumber: " + appVersionNumber);
		AppConfig.appVersionNumber = appVersionNumber;
		AppConfig.zipfilesVersion = appVersionNumber;
		// TEMP :: kernel version is same as app version ( this will likely diverge later )
		AppConfig.appVersionString = appVersionNumber + ' ' + appBuildInfo + ' <' + kernelVersionNumber + '>';
	}

	/**
	 * Sets AppConfig debug based on what has been set by the Jenkin's build process.
	 * If debug is false, all related debug in AppConfig are also deactivated.
	 */
	protected function updateDebugFlag():void
	{
		trace("PopAppBase::updateDebugFlag() sets debug to", isDebugBuild);
		AppConfig.debug = isDebugBuild;
		// if debug is false, deactivate all debug related flags
		if( !AppConfig.debug )
		{
			AppConfig.forceMobile 			= false;
			AppConfig.forceBrowser 			= false;
			AppConfig.ignoreDLC 			= false;
			AppConfig.verifyPathInManifest 	= false;
			AppConfig.resetData 			= false;
		}
		AppConfig.logLevel = 0;
	}

	protected function updateAdsActiveFlag():void
	{
		trace("PopAppBase :: updateAdsActiveFlag() : sets adsActive to", isAdsActive);
		AppConfig.adsActive = isAdsActive;

		// TODO :: turn on/off any other ad related flags
		if( !AppConfig.adsActive )
		{
			AppConfig.adsFromCMS = false;
		}
		else if ((!AppConfig.forceBrowser) && (!AppConfig.forceMobile))
		{
			// RLH: if not forcing mobile or browser, then pull ads from CMS
			// RLH: setting this to true prevents us from testing local ads
			AppConfig.adsFromCMS = true;
		}
	}
	
	protected function updateAssetHost():void
	{
		// TODO :: turn on/off any other ad related flags
		AppConfig.assetHost =  assetHostPrd;
	}

	////////////////////////////// POST-BUILD //////////////////////////////

	/**
	 * The <code>postBuild</code> method performs configuration tasks
	 * which must take place after the <code>Shell</code> begins its startup sequence.
	 * @param shell	A fully-initialized <code>Shell</code> object.
	 *
	 */
	protected function postBuild(shell:Shell):void
	{
		setConsoleVersionString(shell);
	}

	protected function setConsoleVersionString(shell:Shell):void
	{
		if( shell.shellApi.devTools && shell.shellApi.devTools.console )
		{
			shell.shellApi.devTools.console.versionString = AppConfig.appVersionString;
		}
	}

}

}
