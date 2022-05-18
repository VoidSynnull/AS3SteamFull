/* 
FileManager

General purpose file loading and caching manager.  Handles all filetypes.

Usage:

// load a group of files.  These all get cached automatically for retrieval with 'getFile(url)'
loadFiles(["ball.swf", "ball2.swf", "ball3.swf"], filesLoaded, "arg1", "arg2", "arg3");
// load a single file (won't be cached).
loadFile("ball3.swf", fileLoaded, "arg1", "arg2", "arg3");
// load a file and cache it for later retrieval
cacheFile("ball3.swf", cachedFileLoaded, "arg1", "arg2", "arg3");

// When loading a single file, first argument is the file itself as the correct type (displayObject, xml, etc).
//		'content' == null if there is a load error.
public function fileLoaded(content:MovieClip, arg1:*, arg2:*, arg3:*):void
{
trace("fileLoaded : "+ arg1 + "," + arg2 + "," + arg3);
var ball1:MovieClip = this.addChild(content) as MovieClip;
}

// When loading multiple files callback fires with passed arguments when all files are loaded.
public function filesLoaded(arg1:*, arg2:*, arg3:*):void
{
trace("filesLoaded : "+ arg1 + "," + arg2 + "," + arg3);
var ball1:MovieClip = this.addChild(getFile("ball.swf")) as MovieClip;
var ball2:MovieClip = this.addChild(getFile("ball2.swf")) as MovieClip;
var ball3:MovieClip = this.addChild(getFile("ball3.swf")) as MovieClip;

// clear cache when you've retreived all files
clearCache();
}

public function cachedFileLoaded(content:MovieClip, arg1:*, arg2:*, arg3:*):void
{
trace("fileLoaded : "+ arg1 + "," + arg2 + "," + arg3);
// Calling 'getFile(url, true)' clears the file from the cache after retrieval.
var ball1:MovieClip = getFile("ball.swf", true) as MovieClip;
// Can also clear specific file from cache if you didn't pass 'true' to 'getFile'.
clearCache("ball.swf");
}
}
*/

package engine.managers
{
	import com.poptropica.AppConfig;
	import com.poptropica.interfaces.INativeFileMethods;
	
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.system.Capabilities;
	
	import deng.fzip.FZip;
	import deng.fzip.FZipFile;
	
	import engine.Manager;
	import engine.util.Command;
	
	import game.managers.ManifestCheckManager;
	import game.util.PlatformUtils;
	
	import org.assetloader.AssetLoader;
	import org.assetloader.base.AbstractLoader;
	import org.assetloader.base.AssetType;
	import org.assetloader.base.LoaderFactory;
	import org.assetloader.core.ILoader;
	import org.assetloader.signals.ErrorSignal;
	import org.assetloader.signals.LoaderSignal;
	import org.osflash.signals.Signal;
	
	public class FileManager extends Manager
	{
		public function FileManager() 
		{
			
		}
		
		override protected function construct():void
		{
			super.construct();
		}
		
		/**
		 * DEBUG USE
		 * Add a ManifestCheckManager to check manifests during loads 
		 */
		public function addManifestChecker():void
		{
			if( _manifestCheckManager == null )
			{
				_manifestCheckManager = new ManifestCheckManager( super.shellApi );
			}
		}
		
		/**
		 * Load a list of file urls.  Files can be mixed filetypes (excluding zips)
		 * @param   urls : A Vector of urls to load.
		 * @param   [callback] : The function to call when all files have loaded.  
		 * @param   [args] : An array of args to pass to the callback.  There are no default args passed to callback.
		 * @param   [prefix] : A url prefix to add to each file loaded.
		 */
		public function loadFiles(urls:Array, callback:Function = null, args:Array = null, progressCallback:Function = null, fallbackPrefix:String = null):void
		{		
			// NOTE IN USE :: Used to dynamically log manifest
			// if( _manifestCheckManager && _manifestCheckManager.logging )	{ _manifestCheckManager.saveFiles( url ); }
			
			// asset loader is dependent on platform
			var assetLoader:AssetLoader = new AssetLoader(this.shellApi.platform);
			var url:String;

			// check for validity of urls, if valid prepare to load
			for (var n:Number = 0; n < urls.length; n++)
			{		
				// verifyFileLocation is only necessary for mobile devices and manifest checking
				url = verifyFileLocation(urls[n]);
				if(url != null)
				{
					assetLoader.add(url, new URLRequest(url));
				}
				else
				{
					trace("WARNING :: FileManager :: loadFiles : url not found: " + url );
				}
			}
			
			assetLoader.callback = callback;
			assetLoader.callbackArgs = args;
			assetLoader.onComplete.addOnce(filesLoaded);
			assetLoader.onError.addOnce(loadError);
			assetLoader.fallbackPrefix = fallbackPrefix;
			if(progressCallback != null) { assetLoader.onProgress.add(progressCallback); }
			assetLoader.start();
		}
		
		/**
		 * Load a url of any filetype.
		 * @param   url : A url to load.
		 * @param   [callback] : The function to call when all files have loaded.  Gets the file content as its first parameter.  
		 * @param   [args] : An array of args to pass to the callback.  These will appear after the first arg which is always the content.
		 */
		public function loadFile(url:String, callback:Function = null, args:Array = null, progressCallback:Function = null, fallbackPrefix:String = null):ILoader
		{	
			// NOTE IN USE :: Used to dynamically log manifest
			// if( _manifestCheckManager && _manifestCheckManager.logging )	{ _manifestCheckManager.saveFile( url ); }
			
			// verifyFileLocation is only necessary for mobile devices and manifest checking
			url = verifyFileLocation(url);
			if(url != null)
			{
				return createLoader(url, false, callback, args, false, progressCallback, fallbackPrefix);
			}
			else
			{
				//trace( this," :: loadFile :: url could not be verified, trigger callback.");
				args.unshift(null);
				callback.apply(null, args);
			}
			
			return null;
		}
		
		public function loadXMLFromServerAndAppStorage(url:String, callback:Function = null, ...args):void
		{
			this.loadFiles([this.shellApi.serverPrefix + url, "app-storage:/" + url], loadedXMLFromServerAndStorage, [url, callback, args]);
		}
		
		private function loadedXMLFromServerAndStorage(url:String, callback:Function = null, ...args):void
		{
			var xmlServer:XML = this.getFile(this.shellApi.serverPrefix + url, true);
			var xmlStorage:XML = this.getFile("app-storage:/" + url, true);
			args.unshift(xmlServer, xmlStorage);
			if(callback != null)
			{
				callback.apply(null, args);
			}
		}
		
		/**
		 * Load a url of any filetype and cache the content.
		 * @param   url : A url to load.
		 * @param   [callback] : The function to call when all files have loaded.  Gets the file content as its first parameter.  
		 * @param   [args] : An array of args to pass to the callback.  These will appear after the first arg which is always the content.
		 */
		public function cacheFile(url:String, callback:Function = null, args:Array = null, progressCallback:Function = null):void
		{
			// NOTE IN USE :: Used to dynamically log manifest
			// if( _manifestCheckManager && _manifestCheckManager.logging )	{ _manifestCheckManager.saveFile( url ); }
			
			// verifyFileLocation is only necessary for mobile devices and manifest checking
			url = verifyFileLocation(url);
			if(url != null)
			{
				createLoader(url, true, callback, args, false, progressCallback);
			}
			else
			{
				args.unshift(null);
				callback.apply(null, args);
			}
		}
		
		/**
		 * Clear the file content cache.  Defaults to clearing entire cache, optionally you can specify the file content to clear.
		 * @param   [url] : A url to clear.
		 */
		public function clearCache():void
		{
			// clear entire cache
			_cache = new Dictionary();
			
			// add exceptions back in
			for (var n:String in _cacheExceptions)
			{
				_cache[n] = _cacheExceptions[n];
			}
		}
		
		/**
		 * Get file content from the cache.
		 * @param   url : The full url of the content.
		 * @param   [clear] : Clear the content from the cache after retrieving it.
		 */
		public function getFile(url:String, clear:Boolean = false):*
		{	
			//Normalizing data against possible prefixes
			if(_cache["app-storage:/"+url])
			{
				_cache[url] = _cache["app-storage:/"+url];
				delete _cache["app-storage:/"+url];
			}
			else if(_cache["app:/"+url])
			{
				_cache[url] = _cache["app:/"+url];
				delete _cache["app:/"+url];
			}

			// get if file is in cache
			// NOTE :: Not sure if checking for ad path is still necessary, need to confirm with Rick. - bard
			//var file:* = _cache[super.shellApi.adManager.adFileManager.insertAdPrefixToPath(url)];
			var file:* = _cache[url];

			if(!file)
			{
				file = _cache[url];
			}
			
			if(clear)
			{
				_cache[url] = null;
				
				// if xml, do extra cleanup
				/*
				if(file is XML)
				{
					flash.system.System.disposeXML(file);
				}
				*/
			}
			
			/*
			if(file == null)
			{
				trace("FileManager ::: File " + url + " not found in cache.");
			}
			*/
			
			return(file);
		}
		
		public function stopLoad(urls : Array):void
		{
			if(this.stoppableLoaders != null)
			{
				for(var i : int = 0 ; i < urls.length ; i++)
				{
					if(this.stoppableLoaders[urls[i]])
					{
						//Should be ILoader
						this.stoppableLoaders[urls[i]].onProgress.removeAll();
						this.stoppableLoaders[urls[i]].onComplete.removeAll();
						this.stoppableLoaders[urls[i]].onError.removeAll();
						this.stoppableLoaders[urls[i]].stop();
						delete this.stoppableLoaders[urls[i]];
					}
				}
			}
		}
		
		public function deleteFiles(files : Array) : void
		{
			if( _nativeMethods != null)
			{
				if(PlatformUtils.isMobileOS)
				{
					for(var i : int = 0 ; i < files.length ; i++){
						if(_nativeMethods.checkFileInStorage(files[i])){
							_nativeMethods.deleteFile(files[i]);
						}
					}
				}
			}	
		}

		/**
		 * 
		 * @param url
		 * @param cache
		 * @param callback
		 * @param args
		 * @param stoppable
		 * @param progressCallback
		 */
		private function createLoader(url:String, cache:Boolean = false, callback:Function = null, args:Array = null, stoppable:Boolean = false, progressCallback:Function = null, fallbackPrefix:String = null):ILoader
		{
			var factory:LoaderFactory = new LoaderFactory(this.shellApi.platform);
			var loader:ILoader = factory.produce(null, AssetType.AUTO, new URLRequest(url));
			
			if(stoppable)
			{
				this.stoppableLoaders[url] = loader;
			}
			
			if(progressCallback != null)
			{
				loader.onProgress.add(progressCallback);
			}
			
			AbstractLoader(loader).callback = callback;
			AbstractLoader(loader).callbackArgs = args;
			AbstractLoader(loader).cache = cache;
			AbstractLoader(loader).fallbackPrefix = fallbackPrefix;
			
			loader.onComplete.addOnce(fileLoaded);
			loader.onError.addOnce(loadError);
			loader.start();
			
			// NOTE IN USE :: Used to dynamically log manifest
			// if( _manifestCheckManager && _manifestCheckManager.logging )	{ _manifestCheckManager.saveUrlForLogging( url ); }
			
			return loader;
		}
		
		private function filesLoaded(signal:LoaderSignal, files:*, callback:Function= null, args:Array = null):void
		{
			// store loaded files in cache
			for (var file:String in files)
			{
				var origFile:String = file;

				if(_nativeMethods)
				{
					file = _nativeMethods.removeDownloadPath(file);
				}
				
				// remove the possible ad prefixes from cache key
				// NOTE :: Not sure if checking for ad path is still necessary, need to confirm with Rick. - bard
				//file = super.shellApi.adManager.adFileManager.removeAdPrefix(file);
				_cache[file] = files[origFile];
			}
			
			signal.loader.onComplete.removeAll();
			signal.loader.onError.removeAll();
			signal.loader.onProgress.removeAll();
			signal.loader.destroy();
			
			callback = AbstractLoader(signal.loader).callback;
			args = AbstractLoader(signal.loader).callbackArgs;
			
			if(callback)
			{
				callback.apply(null, args);
			}
		}
			
		private function fileLoaded(signal:LoaderSignal, file:*):void
		{
			var loadedCallback:Function = AbstractLoader(signal.loader).callback;
			var args:Array = AbstractLoader(signal.loader).callbackArgs;
			var cache:Boolean = AbstractLoader(signal.loader).cache;
			var filePath:String = signal.loader.request.url;

			if(args != null)
			{
				// NOTE :: Can we check the url instead, or does it not reliably have a zip suffix? - bard
				// NOTE :: Can we check the file type for zip - bard
				if( checkIsZip( String(args[0]) ) )
				{
					var fileName:String = args.shift() as String;			// assumes first argument is file name without prepended path
					var unzipCallBack:Function = args.shift() as Function;	// assumes second argument is unzipCallback function

					if(unzipCallBack != null)	
					{
						if(loadedCallback != null)
						{			
							loadedCallback.apply( null, [false].concat(args) );	// prepend Boolean to act as the isError paramter
						}
						
						unZip(signal.loader.data, fileName, unzipCallBack, args);

						/**We shouldn't need to use this timer, believe it is obsolete, will validate - Bard**/
						/*
						if(!_zipTimer)
						{
							_zipTimer = new WallClock(.5);
							_zipTimer.start();
						}
						_zipTimer.chime.add(Command.create(unZip, signal.loader.data, fileName, unzipCallBack, args ));	
						*/
					}
					else
					{
						unZip(signal.loader.data, fileName, loadedCallback, args);
					}
					loadedCallback = null;	// nullify loadedCallback so that it does not get called later in method
				}
			}
			
			if(cache)
			{
				var fileKey:String = signal.loader.id;
				// NOTE :: Not sure if checking for ad path is still necessary, need to confirm with Rick. - bard
				//fileKey = super.shellApi.adManager.adFileManager.removeAdPrefix(fileKey);
				_cache[fileKey] = file;
			}
			
			if(loadedCallback != null)
			{
				if(args == null) { args = new Array(); }
				
				args.unshift(file);	// add file to front of args Array
				loadedCallback.apply(null, args);
			}
			
			signal.loader.onComplete.removeAll();
			signal.loader.onError.removeAll();
			signal.loader.onProgress.removeAll();
			signal.loader.destroy();
		}
		
		private function loadError(errorSignal:ErrorSignal, loader:ILoader = null):void
		{
			if(loader == null)
			{
				loader = errorSignal.loader;
			}
			
			var callback:Function = AbstractLoader(loader).callback;
			var args:Array = AbstractLoader(loader).callbackArgs;
			
			if(args == null)
			{
				args = new Array();
			}
			
			var isZip:Boolean = checkIsZip( String(args[0]) );
			var alternateUrl:String;
			
			// if loader is an AssetLoader we are dealing with a list of files to download rather than a single one.  
			if(loader is AssetLoader)
			{
				var assetLoader:AssetLoader = loader as AssetLoader;
				var filesToResume:Array = new Array();
				var nextUrl:String;
				var newArgs:Array;
				
				// if we have a fallback prefix defined, try that before giving up.
				if(assetLoader.fallbackPrefix != null)
				{
					// Log for testing
					//shellApi.logError("Loading default location failed for : " + assetLoader.failedIds[0]);
					//shellApi.logError("fallback prefix : " + assetLoader.fallbackPrefix);
					
					alternateUrl = assetLoader.fallbackPrefix + removeAppStorageFromPath(assetLoader.failedIds[0]);
					
					if(PlatformUtils.isMobileOS && isWebUrl(alternateUrl))
					{
						filesToResume.push(removeAppStorageFromPath(assetLoader.failedIds[0]));
					}
					else
					{
						filesToResume.push(alternateUrl);
					}
					
					// Log for testing
					//shellApi.logError("trying fallback url : " + alternateUrl);
				}
				else
				{
					this.ioError.dispatch(assetLoader.failedIds[0], errorSignal.message);
				}
				
				for (var file:String in loader.data)
				{
					_cache[file] = loader.data[file];
				}
				
				for(var n:int = 0; n < assetLoader.ids.length; n++)
				{
					nextUrl = assetLoader.ids[n];
					
					if(assetLoader.loadedIds.indexOf(nextUrl) < 0 && assetLoader.failedIds.indexOf(nextUrl) < 0)
					{
						filesToResume.push(removeAppStorageFromPath(nextUrl));
					}
				}
				
				// if we have fallback url to try for the missing file, download that before proceeding with the rest of the list.
				if(filesToResume.length > 0)
				{
					loader.onComplete.removeAll();
					loader.onError.removeAll();
					loader.onProgress.removeAll();
					loader.destroy();
					
					// if the alternate url is a web address and we're on a device, we download the file to storage rather than a standard load.
					if(PlatformUtils.isMobileOS && alternateUrl != null && isWebUrl(alternateUrl))
					{
						newArgs = [filesToResume, assetLoader.callback, assetLoader.callbackArgs];
						// save the file to the downloads folder, then load it from there using a standard 'loadFiles'.
						_nativeMethods.saveFileToDownloads(alternateUrl, removeServerPrefixFromPath(alternateUrl), loadFiles, newArgs);
					}
					else if(filesToResume.length > 0)
					{
						loadFiles(filesToResume, assetLoader.callback, assetLoader.callbackArgs);
					}
					
					return;
				}				
			}
			else
			{
				if(AbstractLoader(loader).fallbackPrefix != null)
				{
					//shellApi.logError("Loading default location failed for : " + loader.id);
					
					alternateUrl = removeAppStorageFromPath(loader.id);
					alternateUrl = removeServerPrefixFromPath(alternateUrl);
					alternateUrl = AbstractLoader(loader).fallbackPrefix + alternateUrl;
					//shellApi.logError("Trying fallback url : " + alternateUrl);
					
					if(isWebUrl(alternateUrl) && PlatformUtils.isMobileOS && _nativeMethods)
					{
						newArgs = [removeAppStorageFromPath(loader.id), callback, args];
						// save the file to the downloads folder, then load it from there using a standard 'loadFile'.
						_nativeMethods.saveFileToDownloads(alternateUrl, removeServerPrefixFromPath(alternateUrl), loadFile, newArgs);
					}
					else
					{
						loadFile(alternateUrl, callback, args);
					}
					
					return;
				}
				
				this.ioError.dispatch(loader.id, errorSignal.message);
				args.unshift(null);
				
				if(isZip)
				{
					args = new Array(true); // temp code as hardcoded zip callback doesn't expect args.
				}
			}
			
			if(callback)
			{
				callback.apply(null, args);
			}
			
			loader.onComplete.removeAll();
			loader.onError.removeAll();
			loader.destroy();
		}

		public function removeAppStorageFromPath(path:String):String
		{
			var pattern:String = "app-storage:/";
			
			return path.replace(pattern, "");
		}
		
		public function removeServerPrefixFromPath(path:String):String
		{
			var pattern:String = AppConfig.assetHost;
			
			return path.replace(pattern, "");
		}
		
		/**
		 * Store relationship between file url and file in cache Dictionary
		 * @param url - url of file, used to retrieve file in future
		 * @param file - file to maintain reference to
		 */
		public function setCache(url:String, file:*):void
		{
			_cache[url] = file;
		}
		
		/**
		 * Flags a file path so that it never gets deleted from the cache
		 * @param   [url] : A url to add.
		 */
		public function keepInCache(url:String, file:*):void
		{
			_cacheExceptions[url] = file;
		}

		/**
		 * Move file to application storage directory, allowing for Read & Write.
		 * @param fileName
		 */
		public function copyFileToStorage(fileName : String) : void
		{
			if(this._nativeMethods)
			{
				this._nativeMethods.copyFileToStorage(fileName);
			}
		}
		
		/**
		 * Create new file in storage directory, will have Read & Write.
		 * @param bytes
		 * @param name
		 */
		public function createFile(bytes : ByteArray, name : String) : void
		{
			if(this._nativeMethods)
			{
				this._nativeMethods.createFile(bytes, name);
			}
		}
		
		////////////////////////////////////////// ZIPS //////////////////////////////////////////
		
		private function createFZip():void
		{
			if( _fZip != null )
			{
				trace( "WARNING : FileManager :: getDLCContent : fZip already exists, meaning zip is still in process, shouldn't retrieving another until the first is complete.");
			}
			_fZip = new FZip();
		}
		
		// TODO :: Trying to replace this method with loadZip
		/**
		 * Load a url of a zip file for updates to the app.
		 * @param	fileName : The specific name of the zip file.  It is important to separate this from the full URL for deleting the file.
		 * @param   loadedCallBack : The function to call when all files have loaded.  Gets the file content as its first parameter.  
		 * @param   unZipCallback :
		 * @param   progressCallback :
		 * @param   networkPrefix : The network location of the zip file.  Ads might need a different prefix.
		 * @param   [args] : An array of args to pass to the callback.  These will appear after the first arg which is always the content.
		 */
		public function getDLCContent(fileName:String, loadedCallback:Function = null, unZipCallback:Function = null, progressCallback:Function = null, networkPrefix:String = "", args:Array = null) : void
		{
			createFZip();

			// append .zip suffix if not found
			if(fileName.search(".zip") == -1) { fileName = fileName+".zip"; }
			
			if( args != null )
			{
				args.unshift( unZipCallback );
				args.unshift( fileName );
			}
			else
			{
				args = new Array(fileName,unZipCallback);
			}
			
			if(networkPrefix == "")
			{
				networkPrefix = getFullNetworkPath();
			}
			
			createLoader(networkPrefix+fileName, false, loadedCallback, args, true, progressCallback);
		}

		// TODO :: Trying to replace this method with installZip
		/**
		 * Install compressed content (general a zip) 
		 * @param fileName
		 * @param callback
		 * @param unzipCallback
		 * @param progressCallback
		 * @param args
		 */
		/*
		public function installCompressedContent(fileName:String, callback:Function = null, unzipCallback : Function = null, progressCallback:Function = null, args:Array = null):void
		{
			var path:String;
			
			// append .zip suffix if not found
			if(fileName.search(".zip") == -1) { fileName = fileName+".zip"; }
			
			if(!this._nativeMethods.checkFileInStorage(fileName))
			{
				if(this._nativeMethods.checkFileInApp(fileName))
				{
					trace("FileManager :: installCompressedContent : copy file to app storage : " + fileName);
					
					this._nativeMethods.copyFileToStorage(fileName);
					path = _nativeMethods.getFilePathInStorage(fileName);
					
					createFZip();
					
					if( args != null )
					{
						args.unshift( unzipCallback );
						args.unshift( fileName );
					}
					else
					{
						args = new Array(fileName,unzipCallback);
					}
					
					createLoader(path, false, callback, args, true, progressCallback);
				}
				else
				{
					trace("FileManager :: installCompressedContent : Compressed content not found : " + fileName);
					callback();
				}
			}
			else
			{
				trace("FileManager :: File is already in app storage, decompressing...");
				//this.unZip(getFile(url), url, callback);
				path = _nativeMethods.getFilePathInStorage(fileName);
				
				if( args != null )
				{
					args.unshift( unzipCallback );
					args.unshift( fileName );
				}
				else
				{
					args = new Array(fileName,unzipCallback);
				}
				
				createLoader(path, false, callback, args, false, progressCallback);
			}
		}
		*/
		
		
		/**
		 * Used to retrieve zips
		 * QUESTION : Used only on mobile?
		 * @return - string prefix for location of zip files
		 */
		private function getFullNetworkPath():String
		{
			//Watch out for that versionTag var as there might not be zips at the latest tag.  
			//You might need to hard code a different tag for local testing.
			var path : String = (AppConfig.production) ? "/zipfiles/PRD/" : "/zipfiles/DEV/";	
			//trace( "FileManager :: getFullNetworkPath :: " + "http://" + shellApi.siteProxy.fileHost + path + AppConfig.zipfilesVersion + "/" );
			return(String("https://" + shellApi.siteProxy.fileHost + path + AppConfig.zipfilesVersion + "/"));
		}

		/**
		 * Halt loading of zip file. 
		 * @param fileName
		 * @param networkPrefix
		 */
		public function stopZipLoad(fileName:String, networkPrefix:String = ""):void
		{
			// append .zip suffix if not found
			if(fileName.search(".zip") == -1) { fileName = fileName+".zip"; }
			
			if(networkPrefix == "")
			{
				networkPrefix = getFullNetworkPath();
			}
			
			stopLoad([networkPrefix+fileName]);
		}
		
		/**
		 * Load a url of a zip file for updates to the app.
		 * @param	fileName : The specific name of the zip file.  It is important to separate this from the full URL for deleting the file.
		 * @param   loadedCallBack : The function to call when all files have loaded.  Gets the file content as its first parameter.  
		 * @param   unZipCallback :
		 * @param   progressCallback :
		 * @param   networkPrefix : The network location of the zip file.  Ads might need a different prefix.
		 * @param   [args] : An array of args to pass to the callback.  These will appear after the first arg which is always the content.
		 */
		public function loadZip(fileName:String, loadedCallback:Function = null, unZipCallback:Function = null, progressCallback:Function = null, networkPrefix:String = "", args:Array = null) : void
		{
			createFZip();
			
			// append .zip suffix if not found
			if(fileName.search(".zip") == -1) 
			{ 
				fileName = fileName+".zip"; 
			}
			
			if(networkPrefix == "")
			{
				networkPrefix = getFullNetworkPath();
			}
			
			createZipLoader( networkPrefix + fileName, fileName, loadedCallback, unZipCallback, progressCallback, false, args, true );
		}
		
		/**
		 * Install compressed content (general a zip) 
		 * @param fileName
		 * @param callback
		 * @param unzipCallback
		 * @param progressCallback
		 * @param args
		 */
		public function installZip(fileName:String, loadedCallback:Function = null, unzipCallback : Function = null, progressCallback:Function = null, args:Array = null):void
		{
			var path:String;
			
			// append .zip suffix if not found
			if(fileName.search(".zip") == -1) { fileName = fileName+".zip"; }
			
			// check if in local storage, move from app to storage
			if(!this._nativeMethods.checkFileInStorage(fileName))
			{
				// if not in local storage, move there from app storage
				if(this._nativeMethods.checkFileInApp(fileName))
				{
					//trace("FileManager :: installZip : copy file to app storage : " + fileName);
					
					this._nativeMethods.copyFileToStorage(fileName);
					path = _nativeMethods.getFilePathInStorage(fileName);
					
					createFZip();
					createZipLoader(fileName, path, loadedCallback, unzipCallback, progressCallback, false, args, true);
				}
				else
				{
					//trace("FileManager :: installCompressedContent : Compressed content not found : " + fileName);
					if(loadedCallback != null)
					{			
						loadedCallback.apply( null, [false].concat(args) );	// prepend Boolean to act as the isError paramter
					}
				}
			}
			else
			{
				//trace("FileManager :: File is already in app storage, decompressing...");
				createFZip();
				//this.unZip(getFile(url), url, callback);
				path = _nativeMethods.getFilePathInStorage(fileName);
				createZipLoader(fileName, path, loadedCallback, unzipCallback, progressCallback, false, args, true);
			}
		}
		
		/**
		 * Create a loader for zips.
		 * @param fileName
		 * @param networkPrefix
		 * @param cache
		 * @param loadedCallback
		 * @param unZipCallback
		 * @param args
		 * @param stoppable	- if download can be halted.
		 * @param progressCallback
		 * 
		 */
		private function createZipLoader( url:String, fileName:String, loadedCallback:Function = null, unZipCallback:Function = null, progressCallback:Function = null, cache:Boolean = false, args:Array = null, stoppable:Boolean = false ):void
		{
			//trace( "FileManager :: createZipLoader : create loader for url : " + url );
			
			var factory:LoaderFactory = new LoaderFactory(shellApi.platform);
			var loader:ILoader = factory.produce(null, AssetType.AUTO, new URLRequest(url));

			if(stoppable)
			{
				this.stoppableLoaders[url] = loader;
			}
			
			if(progressCallback != null)
			{
				loader.onProgress.add(progressCallback);
			}
			
			AbstractLoader(loader).callback = loadedCallback;
			AbstractLoader(loader).callbackArgs = args;
			AbstractLoader(loader).cache = cache;
			
			loader.onComplete.addOnce( Command.create(zipFileLoaded, fileName, unZipCallback) );
			loader.onError.addOnce( zipFileLoadError );
			loader.start(); 
			
			// NOTE IN USE :: Used to dynamically log manifest
			// if( _manifestCheckManager && _manifestCheckManager.logging )	{ _manifestCheckManager.saveUrlForLogging( url ); }
		}
		
		private function zipFileLoaded(signal:LoaderSignal, file:*, fileName:String, unZipCallback:Function = null ):void
		{
			var loadedCallback:Function = AbstractLoader(signal.loader).callback;
			var args:Array = AbstractLoader(signal.loader).callbackArgs;
			var cache:Boolean = AbstractLoader(signal.loader).cache;
			
			//trace( "FileManager :: zipFileLoaded : unzipping required for file id : " + signal.loader.id + " fileName: " +  fileName );
			
			if(loadedCallback != null)
			{			
				loadedCallback.apply( null, [false].concat(args) );	// prepend Boolean to act as the isError paramter
			}
			
			// if unZipCallback not defined use handler atached to loader?  Unsure of reasoning here? - bard
			if( unZipCallback != null )	
			{
				unZip(signal.loader.data, fileName, unZipCallback, args);
			}
			else	
			{
				unZip(signal.loader.data, fileName, loadedCallback, args);
			}

			if(cache)
			{
				// TODO :: would like ot get rid of add specifics here. -bard
				var fileKey:String = signal.loader.id;
				// NOTE :: Not sure if checking for ad path is still necessary, need to confirm with Rick. - bard
				//fileKey = super.shellApi.adManager.adFileManager.removeAdPrefix(fileKey);
				_cache[fileKey] = file;
			}

			signal.loader.onComplete.removeAll();
			signal.loader.onError.removeAll();
			signal.loader.onProgress.removeAll();
			signal.loader.destroy();
		}
		
		private function zipFileLoadError(errorSignal:ErrorSignal, loader:ILoader = null):void
		{
			if(loader == null)	{ loader = errorSignal.loader; }

			var loadedCallback:Function = AbstractLoader(loader).callback;
			var args:Array = AbstractLoader(loader).callbackArgs;

			this.ioError.dispatch(loader.id, errorSignal.message);
			
			if(loadedCallback)
			{
				if(args == null)	{ args = new Array(); }	// args shoudl not be null, args[0] shoudl equal DLCContentData
				args.unshift( true );						// prepend Boolean to act as the isError parameter
				loadedCallback.apply( null, args );	
			}
			
			loader.onComplete.removeAll();
			loader.onError.removeAll();
			loader.destroy();
		}
		
		private function unZip(_byteArray : ByteArray, zipFileName : String, unzipCallback:Function = null, args:Array = null) : void
		{			
			// if _fZip was never created then there is nothing to uzip, this shouldn't ever happen.
			if (_fZip == null)
			{
				_fZip = new FZip();
				trace( "FileManager :: unZip : FZip was null, terminates unzip process." );
				if(args == null)	{ args = new Array(); }	// args shoudl not be null, args[0] should be equal DLCContentData
				args.unshift( true );						// prepend Boolean to act as the isError parameter
				unzipCallback.apply( null, args );			// prepend Boolean to act as the isError paramter
				return;
			}
			
			_fZip.loadBytes(_byteArray);
			var _fileCount :int = _fZip.getFileCount();			  
			var _fileIndex:int = 0;
			
			while (_fileIndex < _fileCount)
			{
				var zipFile:FZipFile = _fZip.getFileAt(_fileIndex);
				++_fileIndex;
				var fileName:String = zipFile.filename;
				var suffix:String = fileName.slice(fileName.lastIndexOf("."));
				suffix = suffix.toLowerCase();
				var content:ByteArray = zipFile.content;
				content.position = 0;
				
				switch (suffix) 
				{
					case ".png":
					case ".jpg": 
					case ".gif":
					case ".swf":
					case ".xml":
					case ".mp3":
						createFile(content, fileName);
						break;
				}
			}
			
			_fZip.close();
			_fZip = null;
			
			//local zip, needs to be deleted. Remote zips don't save to disk
			if(_nativeMethods.checkFileInStorage(zipFileName))
			{
				_nativeMethods.deleteFile(zipFileName);
			}
			
			if( unzipCallback != null )
			{
				//trace( "FileManager :: unZip : completed decompression for: " + zipFileName );
				if(args == null)	{ args = new Array(); }	// args shoudl not be null, args[0] shoudl equal DLCContentData
				args.unshift( false );						// prepend Boolean to act as the isError parameter
				unzipCallback.apply( null, args );
			}
		}

		private function isWebUrl(path:String):Boolean
		{
			var pattern:String = shellApi.serverPrefix;
			
			if(pattern == null)
			{
				return false;
			}
			else
			{
				return path.indexOf(pattern) > -1;
			}
		}
		
		///////////////////////////////////// PATH METHODS /////////////////////////////////////

		/**
		 * Check for location of url and returns accurate url directory.
		 * Necessary for mobile applicatons as files can be store in the application directory orthe application storage directory.
		 * @param url - url of fiel being searched for
		 * @param returnFail - flag determines if method returns "null" if url is not found, otherwise url is returned
		 * @return - url of file (possibly updated in case of mobile storage)
		 */
		public function verifyFileLocation(url:String, returnFail:Boolean = false):String
		{
			// if on mobile device
			if(this._nativeMethods && PlatformUtils.isMobileOS && !isWebUrl(url))
			{
				// checks for file in Application Storage directory
				if(this._nativeMethods.checkFileInStorage(url))
				{
					// if found in application storage directory return updated url within application storage directory 
					return _nativeMethods.getFilePathInStorage(url);
				}
				else
				{
					// if url found in Application directory, copy to Application Storage directory then return
					if(this._nativeMethods.checkFileInApp(url))
					{
						this._nativeMethods.copyFileToStorage(url);
						return _nativeMethods.getFilePathInApp(url);
					}
					else if(_nativeMethods.checkFileInDownloads(url))
					{
						return _nativeMethods.checkFileInDownloads(url);
					}
					else
					{
						trace( this," :: verifyFileLocation : File is not in the app or in storage : " + url + ".  Try to pull from server? : " + !returnFail);
						// if returning fail, then return null
						if (returnFail)
						{
							return null;
						}
					}
				}
				
				// NOTE :: Not sure if checking for ad path is still necessary, need to confirm with Rick. - bard
				//url = _nativeMethods.getFilePathInStorage(url);
				// need for fetching comm.xml
				if (shellApi.siteProxy == null)
				{
					url = shellApi.serverPrefix + url;
				}
				else
				{
					url = shellApi.siteProxy.secureHost + "/game/" + url;
				}
				// remove app-storage if in url
				url = url.replace("app-storage:/","");
				trace( this," :: verifyFileLocation : Will pull missing file from " + url);
			}
			// if not mobile
			else
			{
				// RLH: if not desktop and not already a full path then add secure host
				if ((Capabilities.playerType != "Desktop") && (url.substr(0,4) != "http"))
				{
					// this was suddenly needed after our secure server work
					url = shellApi.siteProxy.secureHost + "/game/" + url;
				}
			}
			
			// check manifest for url (used for debug purposes)
			if (_manifestCheckManager) { url = _manifestCheckManager.verifyManifestPath( url ); }
			
			return(url);
		}
		
		private function checkIsZip( fileName:String ):Boolean
		{
			return (fileName.search(".zip") != -1);	
		}
		
		/** Path prefix for data files, such as .xml */
		public var dataPrefix:String = "";
		
		/** Path prefix for asset files, such as .swf */
		public var assetPrefix:String = "";
		
		/** Path prefix for general files */
		public var contentPrefix:String = "";
		
		/** Signal used to dispatch errors from FileManager */
		public var ioError:Signal = new Signal(String, String);
		
		/** Dictionary of Loaders using url as key, reference kept so Loader can be stopped */
		public var stoppableLoaders:Dictionary;
		
		/** Dictionary of loaded files using url as key */
		private var _cache:Dictionary = new Dictionary(true);
		
		/** Dictionary of loaded files using url as key, files listed will not be cleared from cache */
		private var _cacheExceptions:Dictionary = new Dictionary();

		//com.poptropica.platformSpecific.nativeClasses.NativeFileMethods
		private var _nativeMethods : INativeFileMethods;
		public function set nativeMethods( nativeMthds:INativeFileMethods):void 	{ _nativeMethods = nativeMthds; }
		public function get nativeMethods():INativeFileMethods { return _nativeMethods; }
		private var _fZip:FZip;

		// DEBUG ONLY :: manifest validation checker
		private var _manifestCheckManager:ManifestCheckManager;
		public function get manifestCheckManager():ManifestCheckManager	{ return _manifestCheckManager; }
	}
}

