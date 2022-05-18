package game.proxy
{
	import game.data.CommunicationData;
	
	import org.osflash.signals.Signal;

	public interface IDataStore
	{
		function get gameHost():String;
		function get fileHost():String;
		function get secureHost():String;
		function get AMFPHPGateWayReady():Signal;
		function get commData():CommunicationData;

		function store(transactionData:DataStoreRequest, callback:Function=null):int;
		function retrieve(transactionData:DataStoreRequest, callback:Function=null):int;

		function init(commData:CommunicationData):void;	// OnlineShellSetupBaseStep
		//function getServerStatus(callback:Function):void;	// ShellApi
		function cancelGatewayRequest(id:int):void;	// AdFileManager
		function useDefaultSecureURL():void;	// OnlineShellSetupBaseStep
	}
}