package com.poptropica.interfaces
{
	public interface IDLCManager
	{
		function checkForUpdates(callback : Function) : void;
		//function getContent(content : String, callback : Function, unZipCallback : Function, progressCallback : Function, errorCallback : Function = null, purchaseCallback : Function = null) : Boolean;
		function deleteContent(content : String, callback : Function) : void;
		function restoreAllPurchases(completeCallback : Function = null, failCallback:Function = null) : void;
		function isInstalled(content : String) : Boolean;
		function setFileInstalled(file:String, value:Boolean, save:Boolean = true) : void
		function setPurchased(content:String, value:Boolean, save:Boolean = true) : void;
		function setCheckSum(file:String, value:String, save:Boolean = true) : void;
		function getPackagedFileState(content:String) : String;
		function isContent(content:String) : Boolean;
		//function cancelDownload() : void;
	}
}