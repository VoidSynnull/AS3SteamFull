package com.poptropica.interfaces
{
	import flash.utils.ByteArray;

	public interface INativeFileMethods
	{
		function createFile(bytes:ByteArray, name:String):void;
		
		/**
		 * Get url of file as it exists in the application storage directory
		 * @param name - basic url of file
		 * @return - url of file as it exists in the application storage directory
		 */
		function getFilePathInStorage(name : String):String;
		
		/**
		 * Get url of file as it exists in the application directory
		 * @param name - basic url of file
		 * @return - url of file as it exists in the application directory
		 */
		function getFilePathInApp(name : String):String;
		
		function copyAssetsFolders(calback:Function):void
		
		/**
		 * Checks to see if file exists in application storage directory
		 * @param name - url of file
		 * @return - return true if file is found in storage, false if it is not
		 */
		function checkFileInStorage(name : String):Boolean;
		
		/**
		 * Checks to see if file exists in application directory
		 * @param name - url of file
		 * @return - return true if file is found in storage, false if it is not
		 */
		function checkFileInApp(name : String):Boolean;
		
		/**
		 * Checks to see if files exists in application storage directory
		 * @param urls - Array of file urls
		 * @return - return true if files are found in storage, false if it is not
		 */
		function checkFilesInStorage(urls : Array):Boolean;
		
		/**
		 * Checks to see if files exists in application directory
		 * @param urls - Array of file urls
		 * @return - return true if files are found in storage, false if it is not
		 */
		function checkFilesInApp(urls : Array):Boolean;
		
		function getFile(name:String):*;
		function copyFileToStorage(name:String):void;
		function copyFilesToStorage(urls:Array,callback:Function):void;
		function deleteFile(name : String) : void;
		function createDownloadsFolder(remove:Boolean = false):void;
		function checkFileInDownloads(url:String):String;
		function getDownloadPath(url:String):String;
		function removeDownloadPath(path:String):String
		function saveFileToDownloads(url:String, localUrl:String = null, callback:Function = null, args:Array = null):void;
	}
}