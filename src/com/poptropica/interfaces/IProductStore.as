package com.poptropica.interfaces
{
	import game.data.dlc.TransactionRequestData;
	import game.data.profile.ProfileData;

	public interface IProductStore
	{			
		function isSupported():Boolean;
		function isAvailable():Boolean;
		function setManualMode(manual:Boolean):void;
		function setUpHost(host:String):void;
		function setProfile(profile:ProfileData):void;
		/**
		 * Initiate a transaction with the product store, type of transactin and necessary data are passed via TransactionRequestData
		 * @param request - TransactionRequestData containing data nad handlers for transaction
		 */
		function requestTransaction(request:TransactionRequestData):void;
		function printTransaction(transaction:Object):void;
		function useLowerCase():Boolean;
	}
}
