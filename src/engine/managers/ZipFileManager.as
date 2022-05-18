/**
 * ZipFileManager
 * 
 * Remote file examples:
 * 
 * 	    _zipFileManager = new ZipFileManager();
	    _zipFileManager.unzipComplete.addOnce(unZipDone);
	    _zipFileManager.unzipProgress.add(zipProgress);
		_zipFileManager.unzipProgress.add(downloadProgress);
		// download a single file 
	    _zipFileManager.installFile("https://github.com/cleversoap/as3-airbrake/archive/master.zip", true);
		 
		// download multiple files, will delete zips when done by default when downloading a sequence of group of files.
		_zipFileManager.installFiles(["https://github.com/cleversoap/as3-airbrake/archive/master.zip", "https://github.com/cleversoap/as3-airbrake/archive/master2.zip"], true);
		 
		private function zipProgress(fileName:String, progress:Number):void
		{
			trace(Unzipping : " + fileName + ".  Percent done : " + (progress * 100) + "%");
		}
		
		private function downloadProgress(fileName:String, progress:Number):void
		{
			trace("Downloading : " + fileName + ".  Percent done : " + (progress * 100) + "%");
		}
		 
		private function unZipDone():void
		{
			// flush the cache when done and cleanup event dispatchers.
			_zipFileManager.cleanup();
		}
	
    Local file examples:
	 
	    _zipFileManager.installFile("carrot.zip");
	    // move to local storage and unzip multiple files, will delete zips when done by default when downloading a sequence of group of files.
		_zipFileManager.installFiles(["carrot.zip", "carrot.misc.zip"]);
*/

package engine.managers
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import deng.fzip.FZip;
	import deng.fzip.FZipErrorEvent;
	import deng.fzip.FZipFile;
	
	import engine.util.Command;
	
	import org.osflash.signals.Signal;

	public class ZipFileManager
	{		
		public function ZipFileManager()
		{
			init();
		}
		
		public function init():void
		{
			_zip = new FZip();
			_zip.addEventListener(Event.OPEN, onZipOpen);
			_zip.addEventListener(Event.COMPLETE, onZipComplete);
			_zip.addEventListener(FZipErrorEvent.PARSE_ERROR, onZipError);
			
			this.unzipComplete = new Signal();
			this.unzipProgress = new Signal(String, Number);
			this.downloadComplete = new Signal();
			this.downloadProgress = new Signal(String, Number);
			this.fileUnzipped = new Signal();
			
			_queue = new Vector.<ZipFileRequest>();
		}
		
		// clear file references and event listeners.
		public function cleanup():void
		{
			_zip.cleanup();
			_queue.length = 0;
			_operationInProgress = false;
			_queueIndex = 0;
			this.unzipComplete.removeAll();
			this.unzipProgress.removeAll();
			this.downloadComplete.removeAll();
			this.downloadProgress.removeAll();
			this.fileUnzipped.removeAll();
		}
		
		public function installFile(url:String, remote:Boolean = false, deleteZipOnComplete:Boolean = true):void
		{
			addToQueue(url, remote, deleteZipOnComplete);
			updateQueue();
		}
		
		// 'install' a list of zip files and optionally delete them after install.
		public function installFiles(urls:Array, remote:Boolean = false, deleteZipOnComplete:Boolean = true):void
		{
			for each (var url:String in urls) 

			{
				addToQueue(url, remote, deleteZipOnComplete);

			}
						
			updateQueue();
		}
						
		public function stopDownload(url:String = null):void
		{
			var request:ZipFileRequest;
			
			if(url == null)
			{
				for each(request in _queue)
				{
					closeLoader(request);
				}
				
				cleanup();
			}
			else
			{
				request = getFromQueue(url, true);
				
				closeLoader(request);
			}
		}
		
		private function closeLoader(request:ZipFileRequest):void
		{
			if(request != null && request.urlLoader != null)
			{
				request.urlLoader.close();
			}
		}
		
		// delete a file from app storage.
		private function deleteFile(url:String):void
		{
			var file:File = File.applicationStorageDirectory.resolvePath(getFileName(url));
			
			if(file.exists)
			{
				file.deleteFile();
			}
		}
		
		private function getFromQueue(url:String, remove:Boolean = false):ZipFileRequest
		{
			for each(var request:ZipFileRequest in _queue)
			{
				if(request.url.indexOf(url) > -1)
				{
					if(remove)
					{
						_queue = _queue.splice(_queue.indexOf(request), 1);
					}
					return request;
				}
			}
			
			return null;
		}
				
		private function addToQueue(url:String, remote:Boolean = false, deleteZipOnComplete:Boolean = true):ZipFileRequest
		{
			var request:ZipFileRequest = new ZipFileRequest(url, remote, deleteZipOnComplete);
			_queue.push(request);
			
			return request;
		}
		
		// If a file needs to be downloaded from the file before unzipping.
		private function downloadAndUnzip(url:String):void
		{
			var urlLoader:URLLoader = new URLLoader();
			var urlRequest:URLRequest = new URLRequest(url);
			
			var request:ZipFileRequest = getFromQueue(url);
			request.urlLoader = urlLoader;
			
			urlLoader.addEventListener(Event.COMPLETE, Command.create(handleBinaryDataLoaded, url), false, 0, true);
			urlLoader.addEventListener(ProgressEvent.PROGRESS, Command.create(handleDownloadProgress, url), false, 0, true);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, Command.create(handleDownloadError, url), false, 0, true);
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			urlLoader.load(urlRequest);
		}
		
		// File destination is determined by the folder structure within it.
		private function moveToStorageAndUnzip(url:String):void
		{
			moveToStorage(url);
			unzip(getFileName(url));
		}
				
		// moves a file from app install directory to the app storage directory.
		private function moveToStorage(url:String):void
		{
			var fileName:String = getFileName(url);
			
			trace("ZipFileManager :: Moving to storage : " + File.applicationStorageDirectory.url + fileName);
			
			// only move if file isn't already there.
			if(!File.applicationStorageDirectory.resolvePath(fileName).exists)
			{
				var file:File = File.applicationDirectory.resolvePath(url);
				var dest:File = File.applicationStorageDirectory.resolvePath(fileName);
				file.copyTo(dest, true);
				dest.preventBackup = true;  // shouldn't do cloud backups of application content.
			}
			else
			{
				handleError("ZipFileManager :: Local file does not exist : " + url);
			}
		}
		
		private function unzip(fileName:String):void
		{
			trace("ZipFileManager :: ZipFileManager :: Trying unzip of : " + File.applicationStorageDirectory.url + fileName);
			
			var file:File = File.applicationStorageDirectory.resolvePath(fileName);
			
			if(file.exists)
			{
				trace("ZipFileManager :: Beginning unzip of : " + File.applicationStorageDirectory.url + fileName);
				_zip.load(new URLRequest(File.applicationStorageDirectory.url + fileName));
			}
			else
			{
				handleError("ZipFileManager :: Zip file not found : " + File.applicationStorageDirectory.url + fileName);
			}
		}
		
		// go through each file in the zip and create it.
		private function unzipFiles(zip:FZip):void
		{
			var fileCount:uint = zip.getFileCount();
			var fileIndex:int = 0;
			var file:FZipFile;
			
			trace("ZipFileManager :: Starting unzip of " + fileCount + " files.");
			
			while(fileIndex < fileCount)
			{
				file = zip.getFileAt(fileIndex);
				
				// if the file is size 0, don't bother creating (directories).
				if(file.sizeCompressed != 0)
				{
					createFile(file.content, file.filename);
				}
				
				fileIndex++;
				
				this.unzipProgress.dispatch(file.filename, fileIndex / fileCount);
			}
			
			this.fileUnzipped.dispatch(file.filename);
			
			_operationInProgress = false;
			
			updateQueue(true);
			
			if(!_operationInProgress)
			{
				this.unzipComplete.dispatch();
			}
		}
		
		private function createFile(bytes:ByteArray, name:String):void
		{
			var outFile:File = File.applicationStorageDirectory.resolvePath(name);
			
			outFile.preventBackup = true;
			var outStream:FileStream = new FileStream(); 
			outStream.open(outFile, FileMode.WRITE); 
			outStream.writeBytes(bytes, 0, bytes.length); 
			outStream.close();
		}
				
		private function onZipComplete(evt:Event):void 
		{
			unzipFiles(evt.target as FZip);
		}
		
		private function onZipOpen(evt:Event):void 
		{
			trace("ZipFileManager :: FZip File Opened.");
		}
		
		private function onZipError(evt:FZipErrorEvent):void 
		{
			handleError("ZipFileManager :: FZip Error : " + evt.text);
		}
				
		private function handleDownloadError(e:IOErrorEvent, url:String):void
		{
			handleError("ZipFileManager :: Error downloading zip : " + e.errorID + " : " + url);
		}
		
		private function handleDownloadProgress(event:ProgressEvent, url:String):void
		{
			if(event.bytesTotal > 0)
			{
				this.downloadProgress.dispatch(url, event.bytesLoaded / event.bytesTotal);
			}
		}
		
		private function handleBinaryDataLoaded(event:Event, url:String):void
		{
			var fileName:String = getFileName(url);
			
			createFile(event.target.data, fileName);
			
			this.downloadComplete.dispatch();
			
			unzip(fileName);
		}
		
		private function updateQueue(advance:Boolean = false):void
		{
			if(!_operationInProgress)
			{
				if(advance)
				{
					_queueIndex++;
				}
				
				if(_queue != null)
				{
					if(_queueIndex > 0)
					{
						var previous:ZipFileRequest = _queue[_queueIndex - 1];
						
						if(previous && previous.deleteOnComplete)
						{
							deleteFile(previous.url);
						}
					}
					
					if(_queueIndex < _queue.length)
					{
						var next:ZipFileRequest = _queue[_queueIndex];
						
						if(next != null)
						{
							_operationInProgress = true;
							
							if(next.remote)
							{
								downloadAndUnzip(next.url);
							}
							else
							{
								moveToStorageAndUnzip(next.url);
							}
						}
					}
					else
					{
						// we've reached the end of the queue, so clear it.
						_queueIndex = 0;
						_queue.length = 0;
					}
				}
			}
		}
			
		private function getFileName(url:String):String
		{
			var parts:Array = url.split("/");
			
			return parts[parts.length - 1];
		}
		
		private function handleError(message:String):void
		{
			throw(new Error(message));
		}
		
		public var unzipComplete:Signal;
		public var unzipProgress:Signal;  // passes back a String, Number
		public var downloadComplete:Signal;
		public var downloadProgress:Signal;
		public var fileUnzipped:Signal;
		private var _zip:FZip;
		private var _queue:Vector.<ZipFileRequest>;
		private var _deleteZipsOnComplete:Boolean = true;
		private var _queueIndex:int = 0;
		private var _operationInProgress:Boolean = false;
	}
}