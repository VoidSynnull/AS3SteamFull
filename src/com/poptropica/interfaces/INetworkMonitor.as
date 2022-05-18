package com.poptropica.interfaces
{
	import org.osflash.signals.Signal;

	public interface INetworkMonitor
	{
		function get networkAvailable():Boolean;
		function set networkAvailable(value:Boolean):void;
		
		function get statusUpdate():Signal;

		function init(url:String):void;
		function start():void;
		function stop():void;
	}
}