package com.poptropica.platformSpecific.browser
{
	
	import com.poptropica.interfaces.IThirdPartyTracker;
	import com.poptropica.platformSpecific.Platform;
	
	import flash.utils.Dictionary;
	
	import game.util.PlatformUtils;
	
	import org.assetloader.core.ILoader;
	import org.assetloader.loaders.SWFLoader;
	import org.assetloader.loaders.WebSWFLoader;
	
	public class BrowserPlatform extends Platform
	{
		public function BrowserPlatform()
		{
			super._classes = new Dictionary();	
			
			super._classes[ILoader] = ( PlatformUtils.inBrowser ) ? WebSWFLoader : SWFLoader
			//_classes[INativeFileMethods] = NativeFileMethods;

			super._classes[IThirdPartyTracker] = BrowserThirdPartyTracker as Class;
			//(_classes[IThirdPartyTracker] as BrowserThirdPartyTracker)
			
			trace(this, "browser");
		}	
	}
}