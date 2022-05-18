package com.poptropica.platformSpecific.browser
{
	import com.poptropica.interfaces.IThirdPartyTracker;
	
	import flash.display.DisplayObjectContainer;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	
	import engine.ShellApi;
	
	import game.util.DataUtils;
	import game.util.PlatformUtils;
	import game.util.Utils;
	
	public class BrowserThirdPartyTracker implements IThirdPartyTracker
	{
		public static const GA_HIT_TYPE_EVENT:String	= 'event';
		public static const GA_HIT_TYPE_PAGEVIEW:String	= 'pageview';

		[Inject]
		public var shellApi:ShellApi;

		private const GOOGLE_ANALYTICS_ACCOUNT:String = "UA-350786-6";
		private var _googleAnalyticsDebugMode:Boolean = false;
		

		public function BrowserThirdPartyTracker(debugContainer:DisplayObjectContainer = null)
		{
			var GAAccount:String = PlatformUtils.inBrowser ? 'window.pageTracker' : GOOGLE_ANALYTICS_ACCOUNT;
			var GAMode:String = PlatformUtils.inBrowser ? 'Bridge' : 'AS3';
		}
		
		public function track(vars:URLVariables):void
		{
			var includeList:Array = [ "start", "hub", "map" ];
			var included:Boolean = includeList.indexOf(vars.cluster) != -1;
			if (!included) {
				return;
			}
			/*
			// filter on cluster
			var excludeList:Array = [
				"arab1",
				"arab2",
				"carnival",
				"carrot",
				"con1",
				"con2",
				"deepDive1",
				"deepDive2",
				"deepDive3",
				"ghd",
//				"home",
				"lands",
//				"map",
				"mocktropica",
				"myth",
				"poptropolis",
				"shrink",
				"survival1",
				"survival2",
				"survival3",
				"survival4",
				"survival5",
				"testIsland",
				"time",
				"videoAd",
				"virusHunter",
				"world1"
			];
			var excluded:Boolean = excludeList.indexOf(vars.cluster) > -1;
			if (excluded) {
				trace("BrowserThirdPartyTracker will NOT track because", vars.cluster, "was found in", excludeList);
				return;
			}
			*/
			/*
			var excludedActions:Array = [
				'NetworkUptimePercentage',
				'AverageSceneFrameRate',
				'TimeSpentInScene',
				'UncaughtErrorThrown'
			];
			excluded = excludedActions.indexOf(vars.event) > -1;
			if (excluded) {
				return;
			}
			*/
			if (vars.event == "AdImpression") {
				if (vars.choice != "Main Street") {
					return;
				}
			} else {
				var includedActions:Array = [
					"SplitFlowSetupCompleted",
					"GoogleServicesReadded",
					"RegistrationCompleted",
					"KeepAlive"
				];
				included = includedActions.indexOf(vars.event) != -1;
				if (!included) {
					return;
				}
			}

			if (ExternalInterface.available) {
				// here's the signature: function GATrackEvent(category, action, label_opt, value_opt, givenDimensions)
				// cluster goes into category
				var category:String = DataUtils.useString(vars.cluster, null);
				// event goes into action
				var action:String = DataUtils.useString(vars.event, null);
				// choice goes into label_opt
				var label_opt:String = DataUtils.useString(vars.choice, null);
				// subchoice goes into value_opt ???
				var value_opt:String = DataUtils.useString(vars.subchoice, null);

				var tracking:String = "GA Track: category:" + category + " action:" + action + " label_opt:" + label_opt + " value_opt:" + value_opt + " dimensions:" + vars.dimensions;
				ExternalInterface.call('dbug', tracking);
				
				var args:Array = ['GATrackEvent', category, action, label_opt, value_opt, vars.dimensions];
				ExternalInterface.call.apply(ExternalInterface, args);
			}
		}
		
		public function trackPageView(island:String, scene:String):void
		{
			var url:String = "/island/" + island + "/" + scene;
			if (ExternalInterface.available) {
				//var tracking:String = "GA Track PageView: url:" + url;
				//ExternalInterface.call('dbug', tracking);
				//ExternalInterface.call('ga', 'send', GA_HIT_TYPE_PAGEVIEW, url);
			}
			try 
			{
				var cacheBusterQueryString:String = "?x=" + Utils.randInRange(1,99999);
				// TODO :: Would like to know more about this call, using contentPrefix seems problematic. - bard
				new URLLoader(new URLRequest( shellApi.fileManager.contentPrefix + 'pageview.xml' + cacheBusterQueryString));
			} 
			catch(e:Error) 
			{
				trace("Error :: BrowserThirdPartyTracker : ignoring error loading pageview.xml:", e.message);
			}
		}

		public function trackPageview(vars:URLVariables):void
		{
			if (ExternalInterface.available) {
				var url:String = "/island/" + vars.island + "/" + vars.scene;
				var tracking:String;
				// here's the function signature: function GATrackPageView(url, age, gender, isMember)
				var args:Array = ['GATrackPageView', url];
				if (vars.hasOwnProperty('dimensions')) {
					trace("YAYview");
					var age:String = vars.dimensions['&cd26'];
					var gender:String = vars.dimensions['&cd27'];
					var isMember:String = vars.dimensions['&cd28'];
					args.push(vars.dimensions['&cd26']);
					args.push(vars.dimensions['&cd27']);
					args.push(vars.dimensions['&cd28']);
					tracking = "GA Track PageView: url:" + url + " age:" + age + " gender:" + gender + " isMember:" + isMember;
					ExternalInterface.call('dbug', tracking);
					ExternalInterface.call.apply(ExternalInterface, args);
				}
				else
				{
					tracking = "GA Track PageView: url:" + url;
					ExternalInterface.call('dbug', tracking);
					ExternalInterface.call.apply(ExternalInterface, args);
				}
			}			
		}
		
		public function translateDomain(appURL:String):void
		{
		}
	}
}
