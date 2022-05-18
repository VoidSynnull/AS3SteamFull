package com.poptropica.platformSpecific.mobile
{
	import com.poptropica.NetworkMonitor;
	
	import flash.events.StatusEvent;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	
	import air.net.URLMonitor;
	
	import engine.ShellApi;
	
	public class MobileNetworkMonitor extends NetworkMonitor
	{
		protected var monitor:URLMonitor;
		public var shell:ShellApi;
	
		//// CONSTRUCTOR ////
	
		public function MobileNetworkMonitor()
		{
		}
	
		//// ACCESSORS ////
	
		//// PUBLIC METHODS ////
	
		//// INTERNAL METHODS ////
	
		//// PROTECTED METHODS ////
	
		protected function onMonitorStatus(e:StatusEvent):void
		{
			if (networkAvailable != monitor.available)
			{
				trace("\nMobileNetworkMonitor NETWORK STATUS:", monitor.available ? 'up' : 'down');
				if(monitor.available == false)
				{
					shell.showNeedNetworkPopup();
				}
			}
			else
			{
				trace("MobileNetworkMonitor ===> MONITOR STATUS UNCHANGED", networkAvailable);
			}
			networkAvailable = monitor.available;
		}
	
		//// PRIVATE METHODS ////
	
		//// INTERFACE IMPLEMENTATIONS ////
	
		// INetworkMonitor
	
		public override function init(url:String):void
		{
			super.init(url);
	
			var request:URLRequest = new URLRequest(url);
			request.method = URLRequestMethod.HEAD;
			monitor = new URLMonitor(request);
			monitor.addEventListener(StatusEvent.STATUS, onMonitorStatus);
		}
	
		public override function start():void
		{
			trace("\nMobileNetworkMonitor START");
			monitor.start();
		}
	
		public override function stop():void
		{
			monitor.stop();
		}
	}
}
