package com.poptropica.platformSpecific
{
	import com.myflashlab.air.extensions.firebase.analytics.AnalyticsEvent;
	import com.myflashlab.air.extensions.firebase.analytics.AnalyticsParam;
	import com.myflashlab.air.extensions.firebase.analytics.FirebaseAnalytics;
	import com.myflashlab.air.extensions.firebase.core.Firebase;
	import com.poptropica.interfaces.IThirdPartyTracker;
	
	import flash.net.URLVariables;

	public class FirebaseTracker implements IThirdPartyTracker
	{
		public function FirebaseTracker() 
		{
			trace("FirebaseTracker :: FirebaseTracker()");
			trace("FirabaseTracker :: " + Firebase.os);
			var addedFirebase:Boolean = Firebase.init();
			trace("FirebaseTracker :: added firebase = " + addedFirebase);
			FirebaseAnalytics.init();
		}
		
		
		public function track(vars:URLVariables):void
		{
			var bundle:AnalyticsParam = new AnalyticsParam();
			bundle.addString(AnalyticsParam.LOCATION, vars.cluster);
			bundle.addString(AnalyticsParam.VALUE, vars.choice);

			FirebaseAnalytics.logEvent(vars.event,bundle);
		}

		public function trackPageView(island:String, scene:String):void
		{
			
			// the last arg to trackScreenView() is a value object which specifies "custom dimensions", in this case we are assigning the app ID to "Custom Dimension 1"
			var dimensions:Object = {};
			var bundle:AnalyticsParam = new AnalyticsParam();
			bundle.addString(AnalyticsParam.LOCATION, island);
			bundle.addString(AnalyticsParam.DESTINATION, scene);

			FirebaseAnalytics.logEvent("PageView",bundle);
		}
		
		public function trackPageview(vars:URLVariables):void
		{
			
			var bundle:AnalyticsParam = new AnalyticsParam();
			bundle.addString(AnalyticsParam.LOCATION, vars.island);
			bundle.addString(AnalyticsParam.DESTINATION, vars.scene);
			bundle.addString(AnalyticsParam.VALUE, vars.dimensions);
			
			FirebaseAnalytics.logEvent("PageView",bundle);
		}
	}
}