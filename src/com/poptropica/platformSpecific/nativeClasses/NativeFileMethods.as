package com.poptropica.platformSpecific.nativeClasses
{
	import com.poptropica.interfaces.INativeFileMethods;
	
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.OutputProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	import engine.util.Command;
	
	public class NativeFileMethods implements INativeFileMethods
	{
		private var copyAssetsCallback : Function;
		private var fileCopyCallback : Function;
		private var foldersToCopy : Array 
		private var foldersCopied:int = 0;
		private var DOWNLOADS_FOLDER:String = "downloads";
		
		public function NativeFileMethods()
		{
			
		}
		
		public function createFile(bytes:ByteArray, name:String):void
		{
			var outFile:File = File.applicationStorageDirectory.resolvePath(name);
			outFile.preventBackup = true;
			var outStream:FileStream = new FileStream(); 
			outStream.open(outFile, FileMode.WRITE); 
			outStream.writeBytes(bytes, 0, bytes.length); 
			outStream.close(); 
		}
				
		public function getFilePathInStorage(name:String):String
		{
			try{
				return File.applicationStorageDirectory.resolvePath(name).url;
			}
			catch(error:Error){
				trace(this,"getFilePathInStorage File access error "+error.name, error.message);
			}
			return null;
		}
		public function getFilePathInApp(name:String):String
		{
			try{
				return File.applicationDirectory.resolvePath(name).url;
			}
			catch(error:Error){
				trace(this,"getFilePathInApp File access error "+error.name, error.message);
			}
			return null;
		}
		
		/**
		 * Checks to see if file exits in application storage
		 * @param name - url of file
		 * @return - return true if file is found in storage, false if it is not
		 */
		public function checkFileInStorage(name:String) : Boolean
		{
			try{
				return File.applicationStorageDirectory.resolvePath(name).exists;
			}
			catch(error:Error){
				trace(this,"File access error "+error.name, error.message);
			}
			return false;
		}
		
		public function checkFilesInStorage(urls:Array) : Boolean
		{	
			for(var i : int = 0 ; i < urls.length ; i++){
				var file : File = File.applicationStorageDirectory.resolvePath(urls[i]);
				if(file.exists == false){
					return false;
				}
			}
			return true;
		}
		
		public function checkFileInApp(name:String) : Boolean
		{
			var file : File = File.applicationDirectory.resolvePath(name);
			return file.exists;
		}
		
		public function checkFilesInApp(urls:Array) : Boolean
		{	
			for(var i : int = 0 ; i < urls.length ; i++){
				var file : File = File.applicationDirectory.resolvePath(urls[i]);
				if(file.exists == false){
					return false;
				}
			}
			return true;
		}
		
		public function getFile(name:String):*
		{
			var file : File = File.applicationStorageDirectory.resolvePath(name);
			return file.data;
		}
		
		public function copyFileToStorage(name:String):void
		{
			var file : File = File.applicationDirectory.resolvePath(name);
			file.copyTo(File.applicationStorageDirectory.resolvePath(name),true);
			
			File.applicationStorageDirectory.resolvePath(name).preventBackup = true;
		}
		
		public function copyFilesToStorage(urls:Array, callback:Function):void
		{
			this.fileCopyCallback = callback;
			
			for(var i : int = 0 ; i < urls.length ; i++)
			{
				var file : File = File.applicationDirectory.resolvePath(urls[i]);
				file.preventBackup = true;
				file.copyTo(File.applicationStorageDirectory,true);
			}
		}
		
		public function deleteFile(name:String):void
		{
			var file:File = File.applicationStorageDirectory.resolvePath(name);
			
			try
			{
				file.deleteFile();
			}
			catch(error:Error)
			{
				trace(this,"delete file failure: " + name + " : " + error.message);
			}
		}		
		
		public function copyAssetsFolders(callback:Function):void
		{
			var folderTest : File = File.applicationDirectory.resolvePath(foldersToCopy[0]);
			
			copyAssetsCallback = callback;
			
			for(var i : int = 0 ; i < foldersToCopy.length ; i++)
			{
				var folder : File = File.applicationDirectory.resolvePath(foldersToCopy[i]);
				folder.addEventListener(Event.COMPLETE, folderCopied, false, 0, true);
				folder.copyToAsync(File.applicationStorageDirectory, true);
			}
		}
		
		public function createDownloadsFolder(remove:Boolean = false):void
		{
			var downloadsPath:String = File.applicationStorageDirectory.url + DOWNLOADS_FOLDER;
			var downloadsFolder:File = new File(downloadsPath);
			
			if(!downloadsFolder.exists)
			{
				downloadsFolder.createDirectory();
			}
			else if(remove)
			{
				downloadsFolder.deleteDirectory(true);
				downloadsFolder.createDirectory();
			}
		}
		
		public function checkFileInDownloads(url:String):String
		{
			var path:String;
			
			try
			{
				path = File.applicationStorageDirectory.url + DOWNLOADS_FOLDER + "/" + url;
				var file:File = new File(path);
				
				if(!file.exists)
				{
					path = null;
				}
			}
			catch(error:Error)
			{
				path = null;
			}
			
			return path;
		}
		
		public function saveFileToDownloads(url:String, localUrl:String = null, callback:Function = null, args:Array = null):void
		{
			if(localUrl == null)
			{
				localUrl = url;
			}
			
			var urlRequest:URLRequest = new URLRequest(url);
			
			// The Loader is used to read a swf file so that we can control the app domain and turn off code import (required for mobile).
			if(url.indexOf(".swf") > -1)
			{
				var context:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain, null);
				context.allowCodeImport = false;

				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.INIT, Command.create(handleLoaded, localUrl, callback, args), false, 0, true);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, Command.create(errorHandler, localUrl, callback, args), false, 0, true);
				loader.load(urlRequest, context);
			}
			else
			{
				// for other file types tha can't contain classes the standard url loader is fine.
				var urlLoader:URLLoader = new URLLoader();
				
				urlLoader.addEventListener(Event.COMPLETE, Command.create(handleBinaryDataLoaded, localUrl, callback, args), false, 0, true);
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR, Command.create(errorHandler, localUrl, callback, args), false, 0, true);
				urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
				urlLoader.load(urlRequest);
			}
		}
		
		private function errorHandler(e:IOErrorEvent, url:String, callback:Function = null, args:Array = null):void
		{
			callback.apply(null, args);
		}
		
		private function handleBinaryDataLoaded(event:Event, url:String, callback:Function = null, args:Array = null):void
		{
			createFileInDownloads(event.target.data, url, callback, args);
		}
		
		private function handleLoaded(event:Event, url:String, callback:Function = null, args:Array = null):void
		{
			createFileInDownloads(LoaderInfo(event.currentTarget).bytes, url, callback, args);
		}
		
		private function createFileInDownloads(data:ByteArray, url:String, callback:Function = null, args:Array = null):void
		{
			// We must create a file in storage by writing the bytearray data to a new file.
			var fileStream:FileStream = new FileStream();
			var savePath:String = getDownloadPath(url);
			
			if(callback)
			{
				fileStream.addEventListener(OutputProgressEvent.OUTPUT_PROGRESS, Command.create(handleFileStreamComplete, callback, args), false, 0, true);
			}
			
			// create a new file asynchronously, and fire the callback when it is ready
			fileStream.openAsync(new File(savePath), FileMode.UPDATE);
			fileStream.writeBytes(data, 0, data.length);
		}
		
		public function getDownloadPath(url:String):String
		{
			var downloadsPath:String = File.applicationStorageDirectory.url + DOWNLOADS_FOLDER;
			
			return downloadsPath + "/" + url;
		}
		
		public function removeDownloadPath(path:String):String
		{
			var pattern:String = DOWNLOADS_FOLDER + "/";
			
			return path.replace(pattern, "");
		}
		
		private function handleFileStreamComplete(event:OutputProgressEvent, callback:Function, args:Array):void
		{
			if(event.bytesPending <= 0)
			{
				callback.apply(null, args);
			}
		}
		
		private function fileCopied(event:Event):void
		{
			event.target.removeEventListener(Event.COMPLETE, fileCopied);	
		}
		
		private function folderCopied(event:Event):void
		{
			event.target.removeEventListener(Event.COMPLETE, folderCopied);
			
			foldersCopied++;
			
			if(foldersCopied == foldersToCopy.length)
			{
				this.copyAssetsCallback();
				this.copyAssetsCallback = null;
				
			}
		}
	}
}