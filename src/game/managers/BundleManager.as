package game.managers
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.Manager;
	import engine.util.Command;
	
	import game.data.bundles.BundleDLCData;
	import game.data.bundles.BundleData;
	import game.data.display.AssetData;
	import game.data.dlc.DLCContentData;
	import game.util.DataUtils;
	
	import org.osflash.signals.Signal;

	public class BundleManager extends Manager
	{

		public function BundleManager() 
		{
			
		}
		
		override protected function construct():void
		{
			_activeBundles = new Vector.<BundleDLCData>;
			_inactiveBundles = new Vector.<BundleDLCData>;
			super.construct();
		}

		/**
		 * Load initial list of bundles ids, both active & inactive.
		 * If fullLoad is true, process will continue to load all active bundles, completeing the BundleData.
		 * @param completeHandler - handler called on setup complete
		 * @param loadContent - flag to determine if setup should load bundle content
		 * @param loadBundleData - flag to determine if setup should load bundle card data
		 * 
		 */
		public function setup( completeHandler:Function = null, loadContent:Boolean = false, loadBundleData:Boolean = false ):void
		{
			var callback:Function = completeHandler;
			if( !_bundlesListed )
			{
				if( loadContent )
				{
					if( loadBundleData )
					{
						callback = Command.create(this.getBundlesContent, Command.create( this.loadActiveBundleDatas, completeHandler) );
					}
					else
					{
						callback = Command.create(this.getBundlesContent, completeHandler );
					}
				}
				shellApi.loadFile( shellApi.dataPrefix + this.DLC_BUNDLE_PATH + this.CONTENT_DATA, parseBundlesConfig, callback );
			}
			else if( !_bundlesContentLoaded && loadContent )
			{
				if( loadBundleData )
				{
					callback = Command.create( this.loadActiveBundleDatas, completeHandler);
				}
				
				this.getBundlesContent( callback );	
			}
			else if( loadBundleData )
			{
				this.loadActiveBundleDatas( completeHandler );
			}
			else
			{
				// everything has already been handled
				if( completeHandler != null ) 	{ completeHandler(); }
			}
		}

		private function parseBundlesConfig( bundlesConfigXml : XML, completeHandler:Function = null ):void
		{
			if( bundlesConfigXml != null )
			{
				if( bundlesConfigXml.target.hasOwnProperty("bundle") )
				{
					var bundles:XMLList = bundlesConfigXml.target.elements("bundle") as XMLList;
					
					var bundleXml:XML;
					var numFiles:int;
					var bundleDLCData:BundleDLCData;
					var dlcContentData:DLCContentData;
					var numBundles:int = bundles.length();
					var i:int;
					var j:int;
					for (i = 0; i < numBundles; i++) 
					{
						// create BundleData
						bundleXml = bundles[i] as XML;
						bundleDLCData = new BundleDLCData();
						bundleDLCData.index = i;
						bundleDLCData.id = DataUtils.getString(bundleXml.attribute("id"));
						bundleDLCData.free = DataUtils.getBoolean(bundleXml.attribute("free"));
						bundleDLCData.active = DataUtils.getBoolean(bundleXml.attribute("active"));
						if( bundleDLCData.active ) { _activeBundles.push(bundleDLCData); }
						else 					{ _inactiveBundles.push(bundleDLCData); }
						
						// if DLCManager exists, create/update DLCContentData
						// DLC status will determine ownership across app
						if( shellApi.dlcManager != null )
						{
							dlcContentData = shellApi.profileManager.globalData.dlc[bundleDLCData.id];
							
							if(dlcContentData == null)	// If bundle dlc is not currently stored, create new instance
							{
								dlcContentData = new DLCContentData();
								dlcContentData.contentId = bundleDLCData.id;
								dlcContentData.purchased = false;
								shellApi.profileManager.globalData.dlc[bundleDLCData.id] = dlcContentData;
							}
							
							dlcContentData.free = bundleDLCData.free;
							dlcContentData.storeId = DataUtils.getString(bundleXml.attribute("storeId"));
							bundleDLCData.active = DataUtils.getString(bundleXml.attribute("active"));
							dlcContentData.packagedFileState = DataUtils.getString(bundleXml.attribute("packagedFileState"));
						
							// store corresponding file ids 
							dlcContentData.files = DataUtils.getArray(bundleXml.attribute("file"));
						}
					}
					
					// if DLCManager exists & bundles were found, create/update DLCFileData (this houses zipSumCheck & file path)
					if( shellApi.dlcManager != null && ( _activeBundles.length + _inactiveBundles.length > 0 ) )
					{
						shellApi.profileManager.saveGlobalData();
						shellApi.loadFile( shellApi.dataPrefix + this.DLC_BUNDLE_PATH + this.FILE_DATA, shellApi.dlcManager.parseCheckSumData, Command.create(zipCheckConfigLoaded, completeHandler) );
						return;
					}
					else
					{
						// no bundles data was found
						trace( "BundleManager : no bundles active or inactive, were defined." ); 
						_bundlesListed = true;
					}
				}
			}
			else 
			{ 
				trace( "Error :: BundleManager : parseActiveBundles : bundlesXml was not defined." );
				_bundlesListed = true;
			}

			// if no bundle data was found we still call handler (absence of bundles should be handled in other methods)
			if( completeHandler != null )	{ completeHandler(); }
		}
		
		private function zipCheckConfigLoaded( completeHandler:Function = null ):void
		{
			// set flag determining if bundle data has been parsed and stored (does not necessarily mean that bundle content has been loaded)
			_bundlesListed = true;
			if( completeHandler != null ) 	{ completeHandler(); }
		}
		
		///////////////////////////////////// DLC CONTENT /////////////////////////////////////
		
		/**
		 * Load and unpackage content related to bundles. 
		 * @param completeHandler - handler called when all loading and unpackaging is complete.
		 * @param loadAllActive - flag determining if all 'active' bundles should be loaded.
		 * @param loadAllOwned - flag determining if all 'purchased' bundles should be loaded.
		 */
		public function getBundlesContent( completeHandler:Function = null, loadAllActive:Boolean = true, loadAllOwned:Boolean = true ):void
		{
			if( shellApi.dlcManager != null )
			{
				// this is only necessary if DLC is being implemented
				if( loadAllActive || loadAllOwned )
				{
					if( shellApi.dlcManager != null )
					{
						var bundleIds:Vector.<String> = new <String>[];
						var bundleDLCData:BundleDLCData;
						var contentData:DLCContentData;
						var i:int;
						if( loadAllActive )
						{
							for (i = 0; i < _activeBundles.length; i++) 
							{
								bundleIds.push( _activeBundles[i].id );
							}
						}
						else	// if loadAllActive is false, loadAllOwned must be true
						{
							for (i = 0; i < _activeBundles.length; i++) 
							{
								bundleDLCData = _activeBundles[i];
								contentData = shellApi.dlcManager.getDLCContentData( bundleDLCData.id );
								if( contentData != null && contentData.purchased )
								{
									bundleIds.push( bundleDLCData.id );
								}
							}
						}
						
						if( loadAllOwned )
						{
							for (i = 0; i < _inactiveBundles.length; i++) 
							{
								// check for owned
								bundleDLCData = _inactiveBundles[i];
								contentData = shellApi.dlcManager.getDLCContentData( bundleDLCData.id );
								if( contentData != null && contentData.purchased )
								{
									bundleIds.push( bundleDLCData.id );
								}
							}
						}
						
						loadBundlesContent( bundleIds, completeHandler ); 
					}
					else
					{
						trace( "Error :: BundleManager : loadBundleZips : DLCManager is not avaialble, thus zips cannot be laoded." )
						if( completeHandler != null )	{ completeHandler(); }
					}
				}
				else
				{
					trace( "Error :: BundleManager : loadBundleZips : loadAllActive & loadAllOwned cannot both be false." )
				}
			}
		}

		/**
		 * Recursive call to DLCManager to load and unpackage content. 
		 * @param bundleIds - list of bundle ids that correspond to DLCContentData ids
		 * @param onComplete
		 */
		private function loadBundlesContent( bundleIds:Vector.<String>, onComplete:Function = null):void
		{
			if( bundleIds.length > 0 )
			{
				var bundleId:String = bundleIds.pop();
				var dlcContentData:DLCContentData = shellApi.profileManager.globalData.dlc[bundleId];
				if( dlcContentData != null )
				{	
					dlcContentData.onContentComplete = Command.create( loadBundlesContent, bundleIds, onComplete);
					dlcContentData.errorSignal = new Signal( DLCContentData );
					dlcContentData.errorSignal.addOnce( Command.create( onBundleError, bundleIds, onComplete) );
					trace( "BundleManager : loadBundlesContent : start load for content: " + dlcContentData.contentId )
					shellApi.dlcManager.loadContentByData( dlcContentData );
				}
				else
				{
					trace("Error : BundleManager :: loadBundlesContent : DLCContentData not found for id: " + bundleId );
					loadBundlesContent( bundleIds, onComplete );
				}
			}
			else
			{
				// set flag determining if bundle data has been parsed and stored (does not necessarily mean that bundle content has been loaded)
				_bundlesContentLoaded = true;
				if( onComplete != null ) { onComplete(); }
			}
		}
		
		private function onBundleError( dlcContentData:DLCContentData, bundleIds:Vector.<String>, onComplete:Function = null ):void
		{
			trace("Error : BundleManager :: onBundleError : error retrieving bundle content: " + dlcContentData.contentId );
			// For now jsut proceed to next bundle, this will at least let the bundle complete even if the zips don't download
			loadBundlesContent( bundleIds, onComplete );
		}
		
		///////////////////////////////////// BUNDLEDATA LOADING /////////////////////////////////////

		/**
		 * Loads and parses xml associated with bundles flagged as active within bundlesConfig.
		 * If using DLC, content must already have been loaded, uncompressed, and moved to app storage.
		 * Data is applied to existing BundleData, completing information necessary for display of bundles in game.
		 * @param completeHandler - called on complete, after called BundleData can be accessed via bundleDatas
		 */
		public function loadActiveBundleDatas( completeHandler:Function = null ):void
		{
			if( _activeBundles != null)
			{
				if( _activeBundles.length > 0 )
				{
					_bundleDatas = new Vector.<BundleData>();
					
					_loadingBundles = _activeBundles.length;
					if( completeHandler != null )	{ _bundlesLoadedHandler = completeHandler }

					var bundleDLCData:BundleDLCData;
					var i:int = 0
					for (i = 0; i < _activeBundles.length; i++) 
					{
						bundleDLCData = _activeBundles[i];
						if( DataUtils.validString(bundleDLCData.id) )
						{
							//loadBundleData( bundleDLCData, true);
							shellApi.loadFile( shellApi.dataPrefix + BUNDLE_PATH + bundleDLCData.id + "/bundle.xml", onLoadedBundleData, bundleDLCData, true );
						}
						else
						{
							trace( "Error :: BundleManager : loadActiveBundleDatas : not a valid bundle id: " + bundleDLCData.id );
							_loadingBundles--;
						}
					}
				}
				else
				{
					trace( "BundleManager : loadActiveBundles : there are no active bundles." ); 
					if( completeHandler != null )	{ completeHandler(); }
				}
			}
			else
			{ 
				trace( "Error :: BundleManager : loadActiveBundles : bundle set has not been defined." ); 
				if( completeHandler != null )	{ completeHandler(); }
			}
		}

		private function onLoadedBundleData( bundleXml : XML, bundleDLCData:BundleDLCData = null, fromActive:Boolean = true ):void
		{
			if( bundleXml != null )
			{
				//  if BundleData not passed, get by id
				var bundleData:BundleData = new BundleData();
				bundleData.parse( bundleXml );
				bundleData.applyDLCData( bundleDLCData );
				_bundleDatas.push( bundleData );
			}
			else
			{
				if( bundleData )
				{
					trace( "Error :: BundleManager : onLoadedBundleData : bundle XML was not found for id: " + bundleDLCData.id  );
				}
			}
			
			_loadingBundles--;
			if( _loadingBundles == 0 )
			{
				if( _bundlesLoadedHandler != null )	{ _bundlesLoadedHandler(); }
			}	
		}
		
		///////////////////////////////////// ASSET LOADING /////////////////////////////////////
		
		public function loadBundleAssets( bundleEntity:Entity, bundleData:BundleData, onComplete:Function = null ):void
		{
			if( bundleData.assetsData.length > 0 )
			{
				var assetData:AssetData = bundleData.assetsData.shift();
		
				var path:String = assetData.assetPath;
				if( DataUtils.validString( path ) )
				{
					shellApi.loadFile( shellApi.assetPrefix + path, assetLoaded, bundleEntity, bundleData, assetData, onComplete);
				}
				else if( assetData.id == BUNDLE_BASE )	//  if card content path not specified use prefix
				{
					shellApi.loadFile( shellApi.assetPrefix + BASE_ASSET, assetLoaded, bundleEntity, bundleData, assetData, onComplete);
				}
				else
				{
					trace( "Error :: BundleManager :: loadBundleAssets : asset path must be given if not a recognized id.");
					loadBundleAssets( bundleEntity, bundleData, onComplete );
				}
			}
			else	// once card assets have been loaded and added, load buttons
			{
				if( onComplete != null )	{ onComplete(); }
			}
		}
		
		private function assetLoaded( displayObject:DisplayObjectContainer, bundleEntity:Entity, bundleData:BundleData, assetData:AssetData, onComplete:Function = null ):void
		{
			if( assetData.id == BUNDLE_BASE )	// if base asset, set internal clips
			{
				bundleData.clip = MovieClip(displayObject).content;	// store clip in BundleData, as the bundleEntity are not directly tied to specific bundles
				
				if( assetData.effectData )
				{
					if( assetData.effectData.filters.length > 0 )
					{
						//bundleData.clip.filters = assetData.effectData.filters;	//apply filters
					}
				}
				
				// set bundle number if specified
				if( bundleData.bundleNum > 0 && bundleData.bundleNum < this.MAX_BUNDLE_NUM )
				{
					MovieClip(MovieClip(bundleData.clip).bundle_mc.number_mc).gotoAndStop(bundleData.bundleNum);
				}
				else
				{
					MovieClip(MovieClip(displayObject).content.bundle_mc.number_mc).visible = false;
				}
			}
			else if( assetData.id == BUNDLE_ICON )	// if icon, add to appropriate container
			{
				MovieClip(MovieClip(bundleData.clip).bundle_mc.icon_container).addChild(displayObject);	
				
				if( assetData.effectData )
				{
					if( assetData.effectData.filters.length > 0 )
					{
						//MovieClip(MovieClip(bundleData.clip).bundle_mc.icon_container).filters = assetData.effectData.filters;	//apply filters
					}
				}
			}
			else
			{
				bundleData.clip.addChild( displayObject );
				
				if( assetData.effectData )
				{
					if( assetData.effectData.filters.length > 0 )
					{
						//MovieClip(displayObject).filters = assetData.effectData.filters;	//apply filters
					}
				}
			}
	
			loadBundleAssets( bundleEntity, bundleData, onComplete );			// recursive
		}
		
		/**
		 * Removes reference to BundleDatas.
		 * Should get called prior to trying to loading Bundle icons within a Group.
		 */
		public function clearBundleData():void
		{
			_bundleDatas = null;
		}

		///////////////////////////////////// HELPERS /////////////////////////////////////
		
		/**
		 * Retrieve BundleData 
		 * @param id - String used as bundle identifier.
		 * @return 
		 */
		public function getBundleData( id:String ):BundleData
		{
			var bundleData:BundleData;
			var i:int;
			for (i = 0; i < _bundleDatas.length; i++) 
			{
				bundleData = _bundleDatas[i];
				if( bundleData.id == id )
				{
					return bundleData;
				}
			}
			return null;
		}

		private var _bundlesLoadedHandler:Function;
		public function set bundlesLoadedHandler( handler:Function ):void	{ _bundlesLoadedHandler = handler; }

		private var _loadingBundles:int = 0;
		
		public function get totalActiveBundles():int	{ return _activeBundles.length; }
		private var _activeBundles:Vector.<BundleDLCData>;
		/** @return - Dictionary of active BundleData, with the BundelData id as Dictionary key. */
		public function get actveBundleDLCDatas():Vector.<BundleDLCData>	{ return _activeBundles; }
		
		private var _inactiveBundles:Vector.<BundleDLCData>;
		/** @return - Dictionary of inactive BundleData, with the BundelData id as Dictionary key. */
		public function get inactiveBundleDLCDatas():Vector.<BundleDLCData>	{ return _inactiveBundles; }
		
		private var _bundleDatas:Vector.<BundleData>; 
		public function get bundleDatas():Vector.<BundleData>	{ return _bundleDatas; }
		
		
		private var _bundlesListed:Boolean = false;
		private var _bundlesContentLoaded:Boolean = false;
		//private var _bundleDatasLoaded:Boolean = false;
		
		
		private static const BUNDLE_BASE:String = "bundleBase";
		private static const BUNDLE_ICON:String = "bundleIcon";
		
		private const BASE_ASSET:String = "bundles/bundle_base/swf";

		private const BUNDLE_PATH:String = "bundles/";
		private const DLC_BUNDLE_PATH:String = "dlc/bundles/";
		private const CONTENT_DATA:String = "bundles.xml";
		private const FILE_DATA:String = "zipCheckSums.xml";
		
		private const MAX_BUNDLE_NUM:int = 7;
	}
}