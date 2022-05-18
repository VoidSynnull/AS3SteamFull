package com.poptropica
{
	import com.poptropica.interfaces.INetworkMonitor;
	
	import org.osflash.signals.Signal;
	
	public class NetworkMonitor implements INetworkMonitor
	{
		private var _statusUpdate:Signal = new Signal(Boolean);
		private var _networkAvailable:Boolean = false;
		private var _initCheck:Boolean = true;
	
		//// CONSTRUCTOR ////
	
		public function NetworkMonitor()
		{
		}
		
		//// ACCESSORS ////
		
		//// PUBLIC METHODS ////
		
		//// INTERNAL METHODS ////
		
		//// PROTECTED METHODS ////
		
		//// PRIVATE METHODS ////
		
		//// INTERFACE IMPLEMENTATIONS ////
		
		// INetworkMonitor
	
		public function get networkAvailable():Boolean
		{
			return _networkAvailable;
		}
		
		// Sometimes other classes will detect a network failure.
		// When they do, they should notify us by invoking this function
		public function set networkAvailable(value:Boolean):void
		{
			if(_networkAvailable != value || _initCheck)
			{
				_initCheck = false;
				_networkAvailable = value;
				_statusUpdate.dispatch(value);
			}
		}
	
		public function get statusUpdate():Signal
		{
			return _statusUpdate;
		}
	
		public function init(url:String):void
		{
			
		}
	
		public function start():void
		{
		}
	
		public function stop():void
		{
		}
	}
}
