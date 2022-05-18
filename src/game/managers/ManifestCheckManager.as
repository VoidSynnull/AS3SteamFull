package game.managers
{
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import engine.ShellApi;
	
	import game.util.DataUtils;

	/**
	 * Use for debugging purposes, checks to see if urls exist in current manifests. 
	 * This is add to the FileManager, and should only be created when debugging.
	 * @author umckiba
	 * 
	 */
	public class ManifestCheckManager
	{
		public function ManifestCheckManager( shellApi:ShellApi )
		{
			_shellApi = shellApi;
			_assetManifests = new Dictionary(true)
		}
		
		////////////////////////////////////////// MANIFESTS //////////////////////////////////////////
		// NOTE :: Used for debug purposes, should not be active on live products
		
		
		
		/**
		 * Load manifests files for given lists of content.
		 * TODO :: Would like to make this less island/bundle specific. - bard
		 * @param islands - Array of Strings for content ids that have correspondingmanifest files.
		 * @param bundes
		 * @param callback
		 */
		public function loadManifests( islands:Array = null, bundes:Array = null, callback:Function = null ):void
		{
			var filesToLoad:Array = new Array();
			var n:int;
			if( islands == null )	{ islands = new Array(); }
			
			// add global island content
			var contentId:String;
			for (n = 0; n < manifests_global.length; n++) 
			{
				contentId = manifests_global[n];
				if( islands.indexOf( contentId ) == -1 )
				{
					islands.push( manifests_global[n] );
				}
			}
			// prepare island manifests for load
			for(n = 0; n < islands.length; n++)
			{
				filesToLoad.push( _shellApi.fileManager.dataPrefix + "scenes/" + islands[n] + "/" + MANIFEST_FILE);
			}
			
			// TODO :: Would like to make this method more generalized, would require making manifests paths not hardcoded
			// prepare bundle manifests for load
			if( bundes != null )
			{
				for(n = 0; n < bundes.length; n++)
				{
					manifests_global.push( bundes[n] );
					filesToLoad.push( _shellApi.fileManager.dataPrefix + "bundles/" + bundes[n] + "/" + MANIFEST_FILE);
				}
			}
			
			if( filesToLoad.length > 0 )
			{
				_shellApi.fileManager.loadFiles(filesToLoad, parseManifest, [filesToLoad, callback]);
				return;
			}
			
			if( callback != null )	{ callback(); }
		}
		
		/**
		 * Parses manifest files.
		 * Creates a Dictionary (key content id) of Vectors.<String> of asset paths.
		 * @param files - Array of manifest text files
		 * @param callback
		 */
		private function parseManifest(files:Array, callback:Function):void
		{
			var file:String;
			var allFiles:Array;
			var contentName:String;
			
			for(var m:int = 0; m < files.length; m++)
			{
				file = _shellApi.fileManager.getFile(files[m]);
				
				if(file != null)
				{
					contentName = String(files[m]).split("/")[2];
					_assetManifests[contentName] = new Vector.<String>();
					allFiles = file.split("\n");
					
					for(var n:int = 0; n < allFiles.length; n++)
					{
						allFiles[n] = allFiles[n].replace("\r", "");
						
						if(allFiles[n] != "" && allFiles[n] != " ")
						{
							_assetManifests[contentName].push(allFiles[n]);
						}
					}
				}
			}
			
			if( callback != null )	{ callback(); }
		}
		
		/**
		 * For debug purposes, checks if url exists within relevant manifests. 
		 * Dispatches an Error to the console if url was not found.
		 * @param url
		 * @return  
		 */
		public function verifyManifestPath(url:String):String
		{
			// check for urls containing exclusion strings 
			var i:int;
			for (i = 0; i < manifest_exclusions.length; i++) 
			{
				if( url.indexOf(manifest_exclusions[i] ) != -1)	{ return url; }
			}
			
			// check current content manifest
			var contentUrls:Vector.<String> = _assetManifests[_shellApi.island];
			if(contentUrls)
			{
				if(	contentUrls.indexOf(url) != -1 ) { return url; }
			}
			else
			{
				_shellApi.fileManager.ioError.dispatch(_shellApi.island, "Island missing manifest.");
			}
			
			// check global content manifests
			for (i = 0; i < manifests_global.length; i++) 
			{
				contentUrls = _assetManifests[ manifests_global[i] ];
				if( contentUrls )
				{
					if(	contentUrls.indexOf(url) != -1 ) { return url; }
				}
				else
				{
					//_shellApi.fileManager.ioError.dispatch(manifests_global[i], "Global missing manifest.");
				}
			}
			
			// if url not found in manifests dispatch error
			_shellApi.fileManager.ioError.dispatch("File missing from manifest",url );
			
			return url;
		}
		
		////////////////////////////////////////// DYNAMIC MANIFEST LOGGING //////////////////////////////////////////
		// NOT IN USE CURRENTLY
		
		/**
		 * Setup so that missing urls are added to manifest log during runtime.
		 */
		private function setupManifetsLogging():void
		{
			loadedFiles = new Array();
		}
		
		public function saveFiles(urls:Array = null):void
		{		
			// NOTE :: Not sure what this is for. -bard
			if( !DataUtils.validString(_shellApi.island) ){
				saveIslandManifest("hub");
			}else{
				saveIslandManifest(_shellApi.island);
			}
			
			for(var i:int=0;i<urls.length;i++)
			{
				this.saveUrlForLogging(urls[i]);
			}
		}
		
		public function saveFile(url:String):void
		{
			if( !DataUtils.validString(_shellApi.island) ){
				saveIslandManifest("hub");
			}else{
				saveIslandManifest(_shellApi.island);
			}
			
			this.saveUrlForLogging(url);
		}
		
		public function saveUrlForLogging(url : String) : void
		{
			url = url.replace("app-storage:/", "")
			url = url.replace("app:/","");
			if(this.loadedFiles.lastIndexOf(url) == -1)
			{
				this.loadedFiles.push(url);
				this.loadedFiles.push("\n")
			}
		}
		
		private function saveIslandManifest(island : String) : void
		{
			if( island != _lastLoggedIsland )
			{
				if( _lastLoggedIsland != "" )
				{
					var bytes : ByteArray = new ByteArray();
					var string : String = String(loadedFiles);
					var regExp:RegExp = /[,]/g;
					var cleanedString:String=string.replace(regExp, "");
					bytes.writeObject(cleanedString);
					//if(_allowNativeMethods)	// NOTE :: Not sure why we need to check for native methods here. -bard
					//{					
						_shellApi.fileManager.createFile(bytes, "data/scenes/"+_lastLoggedIsland+"/mobileAssets.txt");
					//}
					loadedFiles.length = 0;
				}
				_lastLoggedIsland = island;
			}
		}
			
		
		public var manifests_global:Array = new Array( "start", "hub", "map" );
		public var manifest_exclusions:Array = new Array( MANIFEST_FILE, "data/dlc" );	// NOTE :: can add addition exclusion strings (adPrefix for examlpe)
		
		public static const MANIFEST_FILE:String = "mobileAssets.txt";
		private var _assetManifests:Dictionary;	// Dictionary of Vector.<String> containing asset urls, content id used as key
		
		// used for create manifests on player through 
		public var logManifest:Boolean = false;
		public function get logging():Boolean { return logManifest; }
		public var loadedFiles:Array;
		private var _lastLoggedIsland : String = "";
		
		private var _shellApi:ShellApi;
	}
}