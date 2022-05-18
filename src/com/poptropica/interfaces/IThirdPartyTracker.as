package com.poptropica.interfaces
{
	import flash.net.URLVariables;

	public interface IThirdPartyTracker
	{
		function track(vars:URLVariables):void;
		function trackPageView(island:String, scene:String):void;
		function trackPageview(vars:URLVariables):void;
	}
}