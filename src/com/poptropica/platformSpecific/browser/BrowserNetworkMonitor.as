package com.poptropica.platformSpecific.browser
{
	import com.poptropica.NetworkMonitor;
	
	import flash.events.HTTPStatusEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.utils.Timer;
	
	public class BrowserNetworkMonitor extends NetworkMonitor
	{
		private var monitor:URLLoader;
		private var request:URLRequest;
		private var pollTimer:Timer;
		
		//// CONSTRUCTOR ////
		
		public function BrowserNetworkMonitor()
		{
		}
		
		//// ACCESSORS ////
		
		//// PUBLIC METHODS ////
		
		//// INTERNAL METHODS ////
		
		//// PROTECTED METHODS ////
		
		//// PRIVATE METHODS ////
		
		protected function onTimer(e:TimerEvent):void
		{
			monitor.load(request);
		}
		
		private function onHTTPStatus(e:HTTPStatusEvent):void
		{
			trace("BrowserNetworkMonitor::onHTTPStatus()", e.status);
			networkAvailable = ((0 < e.status) && (e.status < 400));
		}
		
		//// INTERFACE IMPLEMENTATIONS ////
		
		// INetworkMonitor
		
		public override function init(url:String):void
		{
			super.init(url);
			
			request = new URLRequest(url);
			request.method = URLRequestMethod.HEAD;
			monitor = new URLLoader(request);
			monitor.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHTTPStatus);
			pollTimer = new Timer(30 * 1000);
		}
		
		public override function start():void
		{
			if (pollTimer.running) {
				return;
			}
			pollTimer.addEventListener(TimerEvent.TIMER, onTimer);
			monitor.load(request);
			pollTimer.start();
		}
		
		public override function stop():void
		{
			pollTimer.stop();
			monitor.close();
			pollTimer.removeEventListener(TimerEvent.TIMER, onTimer);
		}
	}
}