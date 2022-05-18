package game.managers
{
	import com.poptropica.AppConfig;
	import com.poptropica.interfaces.IDLCManager;
	import com.poptropica.interfaces.IProductStore;
	
	import flash.events.TimerEvent;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import engine.Manager;
	import engine.util.Command;
	
	import game.data.dlc.DLCContentData;
	import game.data.dlc.DLCFileData;
	import game.data.dlc.PackagedFileState;
	import game.data.dlc.TransactionRequestData;
	import game.managers.interfaces.IDLCValidator;
	import game.util.DataUtils;
	import game.util.PlatformUtils;
	
	import org.hamcrest.object.nullValue;
	import org.osflash.signals.Signal;
	
	public class DLCManager extends Manager implements IDLCManager
	{		
		public function DLCManager()
		{
		}
		
		//////////////////////////////// INITIALIZATION ////////////////////////////////
		
		protected override function construct():void
		{
			// check for product store and if it is supported
			setupStoreSupport();
		}
		
		/**
		 * Sets flag that determines store support 
		 */
		private function setupStoreSupport() : void
		{
			_storeSupported = false;
			
			if(PlatformUtils.isMobileOS)
			{
				if(AppConfig.iapOn)
				{
					_productStore = shellApi.platform.getInstance(IProductStore) as IProductStore;
					if(_productStore)
					{
						_storeSupported = true;
						if(!_productStore.isSupported())
						{			
							trace("DLCManager :: checkStoreSupport : productStore is not available, can't instantiate");
							_storeSupported = false;
							return;
						}
						
						if(!_productStore.isAvailable())
						{
							trace("DLCManager :: checkStoreSupport : itunes or In APP Purchasing is disabled on this device");
							//_storeSupported = false
						}
						trace("does shellapi exist? "+(shellApi != null));
						if(shellApi)
						{
							trace("does site proxy exist? " + (shellApi.siteProxy != null));
							if(shellApi.siteProxy)
							{
								trace("secure host: " + shellApi.siteProxy.secureHost);
								_productStore.setUpHost(shellApi.siteProxy.secureHost);	
							}
						}
					}
				}
				else	
				{ 
					trace("DLCManager :: checkStoreSupport : iapOn is false, no productStore"); 
				}
			}
			else	
			{ 
				trace("DLCManager :: checkStoreSupport : productStore is only for Mobile Devices"); 
			}
		}
		
		//////////////////////////////// POPTROPICA ISLAND SPECIFIC ////////////////////////////////
		
		/**
		 * Begins process of loading & parsing xml that defines island dlc.
		 * @param dlcConfigPath - xml file defining island dlc content, loaded first converted into DLCContentData
		 * @param dlcZipSumPath - xml file defining file zip sums associated with content, load an dconverted after dlc content
		 * @param completeHandler
		 */
		public function loadIslandDLCData( dlcConfigPath:String = "", dlcZipSumPath:String = "", completeHandler:Function = null) : void
		{
			if( DataUtils.validString(dlcConfigPath) && DataUtils.validString(dlcZipSumPath) )
			{ 
				var loadZipSumXml:Function = Command.create( shellApi.fileManager.loadFile, dlcZipSumPath, parseCheckSumData, [completeHandler] );
				shellApi.fileManager.loadFile( dlcConfigPath, parseIslandDLCConfig, [loadZipSumXml]);
			}
			else
			{
				trace("DLCManager :: loadIslandDLCConfig : invalid path: dlcConfigPath: " + dlcConfigPath + " dlcZipSumPath: " + dlcZipSumPath );
			}
		}
		
		/**
		 * Parse islands specific DLC xml into DLCContentData
		 * @param itemXML
		 */
		private function parseIslandDLCConfig(islandDLCXml:XML, completeHandler:Function = null) : void
		{
			if( islandDLCXml != null )
			{
				// parse xml into DLCContentData
				trace( "DLCManager :: parseIslandDLCConfig : begin parsing island dlc xml." );
				var items : XMLList = islandDLCXml.children().children() as XMLList;
				var i : int;
				for(i = 0 ; i < items.length() ; i++)
				{
					parseIslandDLC( items[i] as XML );
				}
				saveDLCData();
				trace( "DLCManager :: loadedDLCConfig is complete." );
				
				if( completeHandler != null )
				{
					completeHandler();
				}
			}
			else
			{
				trace( "DLCManager :: parseIslandDLCConfig : xml failed to load." );
			}
		}
		
		/**
		 * Parses xml describing island DLC into DLC specific data classes.
		 * @param contentXml
		 */
		public function parseIslandDLC( contentXml:XML ):void
		{
			var islandName:String = DataUtils.getString(contentXml.attribute("island"));
			if( DataUtils.validString(islandName) )
			{
				// check for island DLCContentData in profile
				var dlcContentData:DLCContentData = this.dlcContentDataDict[islandName];
				if(dlcContentData == null)		// if island DLCContentData is ot found, create new one
				{
					trace( "DLCManager :: parseIslandDLC : creating new DLCContentData for island: " + islandName );
					dlcContentData = new DLCContentData();
					//Make sure not to set this true unless you are locally testing a build - it won't unzip an island.
					dlcContentData.contentId = DataUtils.getString(contentXml.attribute("island"));
					dlcContentData.purchased = false;
					dlcContentDataDict[dlcContentData.contentId] = dlcContentData;
				}
				else { trace( "DLCManager :: parseIslandDLC : prior DLCContentData found for island: " + islandName ); }
				
				dlcContentData.packagedFileState = DataUtils.getString(contentXml.attribute("packagedFileState"));
				dlcContentData.storeId = DataUtils.getString(contentXml.attribute("storeID"));
				dlcContentData.free = DataUtils.getBoolean(contentXml.attribute("free"));
				
				//If Android, convert camel to lowercase
				if(_productStore){
					if(_productStore.useLowerCase()){
						dlcContentData.storeId = dlcContentData.storeId.toLowerCase();
					}
				}
				
				trace("DLCManager :: parseIslandDLC : dlcData for :"+dlcContentData.contentId,dlcContentData.storeId,dlcContentData.free,dlcContentData.packagedFileState)
				dlcContentData.files = new Array();
				var filesString:String = DataUtils.getString(contentXml.attribute("files"))
				if( DataUtils.validString(filesString) )
				{
					if(filesString.lastIndexOf(",") == filesString.length-1)
					{
						filesString = filesString.slice(0, filesString.length - 1);
					}
					dlcContentData.files = filesString.split(",");
				}
				else { trace("DLCManager :: parseIslandDLC : There are no files for this island.") }
			}
			else { trace( "Error :: DLCManager :: parseIslandDLC : invalid island name : " + islandName ); }
		}
		
		//////////////////////////////// ZIP SUMS ////////////////////////////////
		
		/**
		 * Parse xml defining zipCheckSums, update DLCFileData to reflect that data.
		 * @param checkSumDataXml - xml shoudl be in a standard format used universally
		 * @param completeHandler - method called on function completion
		 */
		public function parseCheckSumData( checkSumDataXml : XML, completeHandler:Function = null) : void
		{
			trace( "DLCManager :: checkSumDataLoaded : start dlc checkSum xml." );
			//var items : XMLList = checkSumDataXml.children();
			var items : XMLList = checkSumDataXml.elements("item");
			
			//trace(this, "checkSumDataLoaded length", items.length())
			if( _checkSumDictionary == null )	{ _checkSumDictionary = new Dictionary(); }
			
			var itemXml : XML;
			var fileName : String;
			var i : int;
			for(i = 0 ; i < items.length() ; i++)
			{
				itemXml = items[i];
				if( itemXml.hasOwnProperty("file") )
				{
					fileName = DataUtils.getString(itemXml.file);
					
					if( itemXml.hasOwnProperty("checkSum") )
					{
						_checkSumDictionary[fileName] = DataUtils.getString(itemXml.checkSum);
					}
					else { trace( "Error :: DLCManager :: checkSumDataLoaded : element 'checkSum' is not listed within xml: " + itemXml ); }
					
					// check for existing DLCFileData for filename 
					var dlcFileData:DLCFileData = this.dlcFileDataDict[fileName];
					if(!dlcFileData)	
					{
						trace( "DLCManager :: checkSumDataLoaded : creating new DLCFileData for file: " + fileName );
						// if none exists create a new DLCFileData
						dlcFileData = new DLCFileData()
						dlcFileData.checkSum = "";	// NOTE :: We apply checkSum value once zip has successfully loaded and decompressed
						dlcFileData.installed = false;
						this.dlcFileDataDict[fileName] = dlcFileData;
						// TODO :: Do we need to update _checkSumDictionary?
					}
					else if(dlcFileData.checkSum != this._checkSumDictionary[fileName])
					{
						// if DLCFileData already exists, flag for re-install only if checkSum value is different from stored value
						trace( "DLCManager :: checkSumDataLoaded : checkSum value has changed for file: " + fileName );
						dlcFileData.installed = false;
					}
				}
				else { trace( "Error :: DLCManager :: checkSumDataLoaded : element 'file' is not listed within xml: " + itemXml ); }
			}
			
			saveDLCData();
			
			trace( "DLCManager :: initialization is complete." );
			if( completeHandler != null )	{ completeHandler(); }
			//this.checkForUpdates(onProductDetails);	// USE FOR DEBUG
		}
		
		/**
		 * Pass check sum for specific file (usually an ad file)
		 * @param fileID - file ID for zip file
		 * @param checkSum - for zip file
		 * @param dlcData - DLCContentData that file is associated with, necessary to undate validity check
		 * @return - Boolean indicating if requires an install/reinstall
		 */
		public function updateCheckSum( fileID:String, checkSum:String, dlcData:DLCContentData ) : Boolean
		{
			trace( "DLCManager :: updateCheckSum : fileID: " + fileID);
			var hasNewCheckSum:Boolean = false;
			// create dictionary if it doesn't exist, add checksum to dictionary
			if( _checkSumDictionary == null ) { _checkSumDictionary = new Dictionary(); }
			_checkSumDictionary[fileID] = checkSum;
			
			// check for existing DLCFileData by fileID 
			var dlcFileData:DLCFileData = this.dlcFileDataDict[fileID];
			if(!dlcFileData)	// if none exists create a new DLCFileData
			{
				trace( "DLCManager :: updateCheckSum : creating new DLCFileData for file: " + fileID );
				var fileData:DLCFileData = new DLCFileData();
				fileData.checkSum = "";	// NOTE :: We apply checkSum once zip has successfully loaded and decompressed
				fileData.installed = false;
				this.dlcFileDataDict[fileID] = fileData;
				
				hasNewCheckSum = true;
			}
			else if(dlcFileData.checkSum != checkSum)
			{
				// if check sums don't match requires new install
				// if DLCFileData already exists, flag for re-install only if checkSum value is different from stored value
				trace( "DLCManager :: updateCheckSum : file has been set for reinstall: " + fileID );
				dlcFileData.installed = false;
				
				hasNewCheckSum = true;
			}
			
			// if an install/reinstall is required reset DLCContentData for validation checking & save DLC changes
			if( hasNewCheckSum )
			{
				if( dlcData.validationRequired ) 
				{ 
					dlcData.isValid = true;
					dlcData.checkValidity = true; 
				}
				saveDLCData();
			}
			return hasNewCheckSum
		}
		
		//////////////////////////////// CONTENT QUEUE ////////////////////////////////
		
		/**
		 * Start process for downloading group of content.
		 * @param contentId
		 * @param onComplete
		 * @param onProgress
		 * @param onError
		 * @param onStateChange
		 */
		public function queueContentById( contentId:String, onComplete:Function = null, onProgress:Function = null, onError:Function = null, onStateChange:Function = null):void
		{
			var dlcContentData:DLCContentData = dlcContentDataDict[contentId];
			queueContentByData( dlcContentData, onComplete, onProgress, onError, onStateChange );
		}
		
		/**
		 * Start process for downloading group of content.
		 * @param dlcContentData
		 * @param onComplete
		 * @param onLoadProgress
		 * @param onError
		 * @param onStateChange
		 */
		public function queueContentByData( dlcData:DLCContentData, onComplete:Function = null, onLoadProgress:Function = null, onError:Function = null, onStateChange:Function = null, validator:IDLCValidator = null ):void
		{
			if( dlcData != null )
			{
				// if content is in a compressed format it will get added to queue
				if(dlcData.packagedFileState == PackagedFileState.LOCAL_COMPRESSED || dlcData.packagedFileState == PackagedFileState.REMOTE_COMPRESSED)
				{
					// apply given handlers
					applyDLCHandlers( dlcData, onComplete, onLoadProgress, onError, onStateChange, validator);
					// add to content queue
					this.addToQueue( dlcData );	
				}
				else 
				{ 
					trace("DLCManager :: queueContentByData : content must be uncompressed, does not need DLCManager."); 
				}
			}
			else
			{
				trace("Error : DLCManager :: queueContentByData : DLCContentData is null" );
				if( onError != null )	
				{ 
					onError( null ); 
				}
			}
		}
		
		public function addToQueue( dlcData : DLCContentData ) : void
		{
			// make sure content is not already added to queue
			if( _contentQueue.indexOf( dlcData ) == -1 )
			{
				trace( "DLCManager :: addToQueue : adding content " + dlcData.contentId + " to queue.");
				_contentQueue.push( dlcData );
			}
			else
			{
				trace( "DLCManager :: addToQueue : content " + dlcData.contentId + " already in queue.");
			}
		}
		
		/**
		 * Removes content id from queue 
		 * @param contentId
		 */
		public function removeFromQueue( dlcData : DLCContentData) : void
		{
			// make sure content is not already added to queue
			var index:int = _contentQueue.indexOf( dlcData );
			if( index != -1 )
			{
				_contentQueue.splice( index, 1 );
			}
			else
			{
				trace( "DLCManager :: addToQueue : contnent " + dlcData.contentId + " not found in queue, cannot be removed.");
			}
		}
		
		/**
		 * Removes everything currently in queue, all DLCContentData in queue is reset
		 */
		public function clearQueue() : void
		{
			for (var i:int = 0; i < _contentQueue.length; i++) 
			{
				_contentQueue[i].reset();
			}
			_contentQueue.length = 0;
		}
		
		public function startNextInQueue( onComplete:Function = null, onProgress:Function = null, onError:Function = null, onStateChange:Function = null ) : DLCContentData
		{
			if( _contentQueue.length > 0 )
			{
				var dlcData:DLCContentData = _contentQueue[_contentQueue.length-1];
				if( dlcData )
				{
					trace( "DLCManager :: startNextInQueue :: start load process for DLC: " + dlcData.contentId);
					loadContentByData( dlcData, onComplete, onProgress, onError, onStateChange );
					return dlcData;
				}
				else
				{
					trace( "Error :: DLCManager :: startNextInQueue :: no DLC was not found in queue");
				}
			}
			return null;
		}
		
		public function getNextInQueue() : DLCContentData
		{
			if( _contentQueue.length > 0 )
			{
				return _contentQueue[_contentQueue.length-1];
			}
			return null;
		}
		
		public function get queueTotal():int
		{
			if( _contentQueue )
			{
				return _contentQueue.length;
			}
			return 0;
		}
		
		//////////////////////////////// CONTENT DOWNLOAD ////////////////////////////////
		
		/**
		 * Start process for downloading group of content.
		 * @param contentId
		 * @param onComplete
		 * @param onProgress
		 * @param onError
		 * @param onStateChange
		 */
		public function loadContentById( contentId:String, onComplete:Function = null, onProgress:Function = null, onError:Function = null, onStateChange:Function = null):void
		{
			// check dlc dictionary, only dlc specified at start up will listed (so ads content will not)
			var dlcContentData:DLCContentData = dlcContentDataDict[contentId];
			loadContentByData( dlcContentData, onComplete, onProgress, onError, onStateChange );
		}
		
		/**
		 * Start process for downloading group of content.
		 * @param dlcContentData
		 * @param onComplete
		 * @param onLoadProgress
		 * @param onError
		 * @param onStateChange
		 */
		public function loadContentByData( dlcData:DLCContentData, onComplete:Function = null, onLoadProgress:Function = null, onError:Function = null, onStateChange:Function = null ):void
		{
			if( dlcData != null )
			{
				if(dlcData.packagedFileState == PackagedFileState.LOCAL_COMPRESSED || dlcData.packagedFileState == PackagedFileState.REMOTE_COMPRESSED)
				{
					applyDLCHandlers( dlcData, onComplete, onLoadProgress, onError, onStateChange);
					
					// begin load, if current content is only content in queue, else will be called when current content has completed
					this.addToQueue( dlcData );	// add to queue, gets removed when complete, cancelled, or errors
					if( !_isLoading )
					{
						_isLoading = true;
						loadContentFile( dlcData );
					}
				}
				else
				{
					// trace("DLCManager :: loadContentFromData : content must be uncompressed"); 
					if( onComplete != null ){ 
						onComplete(); 
					}else if ( dlcData.onContentComplete != null ){
						dlcData.onContentComplete();
					}
				}
			}
			else
			{
				trace("Error :: DLCManager :: loadContentFromData : DLCContentData is null" );
				if( onError != null )	
				{ 
					onError( dlcData ); 
				}
				else if ( dlcData.errorSignal != null )
				{
					dlcData.errorSignal.dispatch(dlcData);
				}
			}
		}
		
		/**
		 * Cancels all current downloads.
		 * Triggered by user.
		 */
		public function cancelAllContentDownloads():void
		{
			// go through content queue, cancelling any currently active file downloads associated with content
			for (var i:int = 0; i < _contentQueue.length; i++) 
			{
				cancelContentDownload( _contentQueue[i].contentId );
			}
			this.onDownloadCancel.dispatch();
		}
		
		/**
		 * Cancels a particular content download. 
		 * @param contentId
		 * @param dlcContentData
		 * @param startNextInQueue
		 * @return 
		 */
		public function cancelContentDownload( contentId:String = "", dlcData:DLCContentData = null, startNextInQueue:Boolean = false ):Boolean
		{
			if( dlcData == null)
			{
				dlcData = dlcContentDataDict[contentId];
			}
			
			if( dlcData )
			{
				if( DataUtils.validString( dlcData.currentFile ) )
				{
					trace("DLCManager :: cancelContentDownload : all files loaded for content: " + dlcData.contentId);  
					
					shellApi.fileManager.stopZipLoad( dlcData.currentFile );
					
					// TODO :: Want better handling & clean up here.
					
					_isLoading = false;
					if( dlcData.onDownloadCancel != null )	{ dlcData.onDownloadCancel() };
					
					removeFromQueue( dlcData );
					dlcData.reset();
					
					if( startNextInQueue )	{ startNextInQueue(); }
					return true;
				}
			}
			return false;
		}
		
		/**
		 * Loads a single content file, likely part of a content group.
		 * Called recursively until all related content has completed.
		 * @param dlcContentData
		 */
		private function loadContentFile( dlcData:DLCContentData ):void
		{
			// check for all files loaded
			if( dlcData.fileIndex == dlcData.files.length )
			{
				trace("DLCManager :: loadContentFile : all files loaded for : " + dlcData.contentId);  
				removeFromQueue( dlcData );
				_isLoading = false;
				
				// check if validation is needed
				if( dlcData.checkValidity && dlcData.validatorDelegate != null )	// check for validation
				{ 
					// TODO :: How do we handle completion, need to better standardize the validation step
					dlcData.validatorDelegate.validateContent(dlcData, this.onContentValidated);
					return;
				}
				else if( dlcData.onContentComplete != null )	
				{ 
					// NOTE :: onContentComplete handler is responsible for triggering additional content loads
					dlcData.onContentComplete(); 
				}
				dlcData.reset();
			}
			else
			{
				var fileId:String = String(dlcData.files[dlcData.fileIndex]);
				fileId = fileId.replace(".zip","");	// TODO :: This shoudln't be necessary, but seems that ads was adding .zip to file ids at some point
				var dlcFileData:DLCFileData = dlcFileDataDict[fileId];
				dlcData.fileIndex++;
				
				// if DLCFileData is not defined or has yet to be installed, add to list of files to install
				// NOTE :: DLCFileData == null is acceptable in case of ads, as they don't use zipsums, seems like they should though. -bard
				
				if( dlcFileData )
				{
					if( !dlcFileData.installed )
					{
						// if any content file requires an install & the DLCData requires validation we need to invalidate the DLCData so it gets validated again
						if( dlcData.validationRequired ) { dlcData.checkValidity = true; }
						
						dlcData.currentFile = fileId;
						var args:Array = [dlcData];	// these args are what is sent back with the handlers
						if( dlcData.packagedFileState == PackagedFileState.REMOTE_COMPRESSED )
						{
							//trace("DLCManager :: loadContentFile : load remote compressed content for file : " + fileId);  
							dlcData.state = CONTENT_LOADING;
							shellApi.fileManager.loadZip( fileId, dlcFileDownLoaded, dlcFileUnzipped, dlcData.onLoadProgress, dlcData.networkPath, args );
							
						}
						else
						{
							//trace("DLCManager :: loadContentFile : install local compressed content for file : " + fileId); 
							dlcData.state = CONTENT_INSTALLING;
							shellApi.fileManager.installZip( fileId, dlcFileDownLoaded, dlcFileUnzipped, dlcData.onLoadProgress, args);
						}
					}
					else
					{
						// if already installed proceed to next file.
						dlcData.state = CONTENT_LOADED;
						loadContentFile( dlcData );	
					}
				}
				else
				{
					trace( this," :: loadContentFile : could not find DLCFileData of id: " + fileId + " for content: " + dlcData.contentId );
					dlcData.errorSignal.dispatch( dlcData );
				}
			}
		}
		
		/**
		 * Handler called when zip has been loaded, successfully or not.
		 * @param isError - flag determining if there was an error during loading.
		 * @param dlcContentData
		 */
		private function dlcFileDownLoaded( isError:Boolean = false, dlcData:DLCContentData = null, ...args ) : void
		{
			if(isError)
			{
				if( dlcData )
				{
					trace( "Warning :: DLCManager :: error with DLC file download for content: " + dlcData.contentId +  ", attempting recovery." );
					removeFromQueue( dlcData );
					_isLoading = false;
					dlcData.errorSignal.dispatch( dlcData );
					dlcData.reset();
					
					// TODO :: If there is an error may want to halt everything and reset dlcContent, need recovery mechanism. -bard
					//loadContentFile( dlcContentData );
				}
				else
				{
					trace( "FATAL ERROR :: DLCManager :: error with DLC file download, DLCContentData was not returned, this shouldn't happen" );
				}
			}
			else
			{
				// once downloaded content is installed by FileManager, update state
				if( dlcData )
				{
					dlcData.state = CONTENT_INSTALLING;
				}
			}
		}
		
		/**
		 * Handler for completion of dlc unzip.
		 * On unzip we update installed flag and apply checksum
		 */
		private function dlcFileUnzipped( isError:Boolean = false, dlcData:DLCContentData = null ) : void
		{
			if( !isError && dlcData != null )
			{
				var dlcFileData:DLCFileData = dlcFileDataDict[dlcData.currentFile];
				if( dlcFileData != null )
				{
					dlcFileData.installed = true;
					dlcFileData.checkSum = this._checkSumDictionary[dlcData.currentFile];
					saveDLCData();
				}
				else
				{
					trace("WARNING :: DLCManager :: dlcFileUnzipped : DLCFileData not found for " + dlcData.currentFile );
				}
				
				dlcData.state = CONTENT_INSTALLED;
				loadContentFile( dlcData );	// begin loading next file
			}
			else
			{
				if( dlcData != null )
				{
					// TODO :: Need recovery method here
					trace( "Error : DLCManager :: dlcFileUnzipped : error with zip decompression and/or DLC data not returned.");
					removeFromQueue( dlcData );
					_isLoading = false;
					dlcData.errorSignal.dispatch( dlcData );
					dlcData.reset();
				}
				else
				{
					trace( "FATAL ERROR :: DLCManager :: error with DLC file decompressing, DLCContentData was not returned, this shouldn't happen" );
				}
			}
		}
		
		/**
		 * Handler for the completion of content validation process.
		 * During validation process the content's isValid flag should of been set appropriately.
		 * @param dlcData
		 */
		public function onContentValidated( dlcData:DLCContentData ):void
		{
			if( dlcData )
			{
				if( dlcData.isValid )
				{
					dlcData.onContentComplete();
				}
				else
				{
					trace(this," :: onContentValidation : content was invalid: " + dlcData.contentId );
					dlcData.errorSignal.dispatch( dlcData );
				}
				dlcData.reset();
			}
			else
			{
				trace("ERROR :: DLCManager :: onContentValidation : DLCContentData must be returned." );
			}
		}
		
		//////////////////////////////// PURCHASING ////////////////////////////////
		
		/**
		 * Begin purchase process for store content
		 * @param contentId - String id of content being purchased (this is not the store id)
		 * @param completeCallback - Function called when purchase is completed successfully, parameters returned are [ DLCContentData, TransactionRequestData ]
		 * @param cancelCallBack - Function called if purchase is cancelled, parameters returned are [ DLCContentData, TransactionRequestData ]
		 * @param failureCallBack - Function called when purchase process encounters an error, parameters returned are [ DLCContentData, TransactionRequestData ]
		 */
		public function attemptPurchase( contentId:String, completeCallback:Function = null, cancelCallBack:Function = null, failureCallBack:Function = null ) : void
		{
			var request:TransactionRequestData;
			var dlcContentData:DLCContentData = dlcContentDataDict[contentId];
			
			if( dlcContentData != null )
			{
				if( completeCallback != null )	{ dlcContentData.onPurchaseComplete = completeCallback; }
				
				if( dlcContentData.free || dlcContentData.purchased )	// check if free or already purchased
				{
					if( dlcContentData.onPurchaseComplete != null )	
					{ 
						request = TransactionRequestData.requestPurchase(dlcContentData.storeId);
						if( dlcContentData.free )
						{
							request.errorType = "Free Item";
							request.message = "This is a free item.";
						}
						else if( dlcContentData.purchased )
						{
							request.errorType = "Already Purchase";
							request.message = "Item has already been purchased.";
						}
						dlcContentData.onPurchaseComplete( dlcContentData, request ); 
					}
					else 
					{ 
						trace("Error : DLCManager :: purchaseContent : onPurchaseComplete was not specified"); 
						if( failureCallBack != null )	
						{ 
							request = TransactionRequestData.requestPurchase(dlcContentData.storeId);
							request.errorType = "Internal Error";
							request.message = "Must specify a callback for purchase completion.";
							failureCallBack(dlcContentData, request); 
						}
					}
				}
				else													// requires purchase
				{
					if( cancelCallBack != null )		{ dlcContentData.onPurchaseCancel = cancelCallBack; }
					if( failureCallBack != null )		{ dlcContentData.onPurchaseFail = failureCallBack; }
					
					trace( "DLCManager :: attemptPurchase : for storeId: " + dlcContentData.storeId);
					
					if(!AppConfig.iapOn)	// FOR TESTING ONLY :: For testing without live store
					{
						var timer:Timer = new Timer(3000, 1)
						timer.addEventListener( TimerEvent.TIMER_COMPLETE, function(event:TimerEvent):void{ TransactionRequestData.requestPurchase(dlcContentData.storeId).completed(); })
						timer.start();
						return;
					}
					else
					{
						if(shellApi.networkAvailable() && _storeSupported)
						{
							shellApi.track("DLCManager :: PurchaseAttempted :",dlcContentData.storeId,contentId);
							// NOTE :: If we reintroduce receipt validation will need to set host = shellApi.siteProxy.gameHost
							request = TransactionRequestData.requestPurchase(dlcContentData.storeId,onTransactionComplete);
							_productStore.requestTransaction( request );
						}
						else
						{
							trace( "DLCManager :: purchaseContent: network not available or store not supported.")
							request = TransactionRequestData.requestPurchase(dlcContentData.storeId);
							if( !_storeSupported )
							{
								request.errorType = "Store Not Supported";
								request.message = "The store is not currently supported\non this device.";
							}
							else
							{
								request.errorType = "Connection Required";
								request.message = "You must have an internet connection\nto access the store.";
							}
							if( dlcContentData.onPurchaseFail != null )	{ dlcContentData.onPurchaseFail( dlcContentData, request ); }
						}
					}
				}
			}
			else
			{
				trace( "ERROR :: DLCManager :: purchaseContent: no content found for: " + contentId );
				if( failureCallBack != null )	
				{ 
					request = TransactionRequestData.requestPurchase("");
					request.errorType = "Invalid Content";
					request.message = "Requested store item was not found.";
					failureCallBack(null, request); 
				}
			}
		}
		
		/**
		 * Restore all previously made transactions/purchases.
		 * Returns TransactionRequestData with handlers.
		 * @param restoreAllCallback - Function called if all purchases restored, parameters returned are [ TransactionRequestData ]
		 * @param failureCallBack - Function called if restore fails, parameters returned are [ TransactionRequestData ]
		 */
		public function restoreAllPurchases( restoreAllCallback:Function = null, failureCallBack:Function = null ) : void
		{
			var request:TransactionRequestData;
			
			// For testing without live store. 
			// Restores everything stored in dlcContentDataDict, not necessarily accurate. -bard
			if(!AppConfig.iapOn)	// FOR TESTING ONLY :: For testing without live store
			{
				for(var content:String in dlcContentDataDict)
				{
					this.setPurchased(content,true,false);
				}
				saveDLCData();
				
				if( restoreAllCallback != null ) 	
				{ 
					request = TransactionRequestData.requestRestoreAll();
					request.errorType = "IAP Testing";
					request.message = "Purchases have been restored for testing.";
					restoreAllCallback(request); 
				}
				return;
			}
			
			trace(this," :: restoreAllPurchases : storeSupported: " +_storeSupported);
			if( shellApi.networkAvailable() )
			{
				if(_storeSupported)
				{
					shellApi.track("RestorePurchasesAttempted");
					
					// NOTE :: If we reintroduce receipt validation will need to set host = shellApi.siteProxy.gameHost
					request = TransactionRequestData.requestRestoreAll(onTransactionComplete,restoreAllCallback,failureCallBack,this.transactionRestored );
					_productStore.requestTransaction( request );	
				}
				else
				{
					if( failureCallBack != null )
					{
						request = TransactionRequestData.requestRestoreAll();
						request.errorType = "Store Not Supported";
						request.message = "The store is not currently supported\non this device.";
						failureCallBack(request)
					}
				}
			}
			else
			{
				if( failureCallBack != null )
				{
					request = TransactionRequestData.requestRestoreAll();
					request.errorType = "Connection Required";
					request.message = "You must have an internet connection\nto access the store.";
					failureCallBack(request);
				}
			}
		}
		
		/**
		 * USED FOR DEBUG
		 * Request product details from product store (if supported)
		 * @param callback - Function receives 2 arguments, arg[0] Boolean for request success, arg[1] Array of String with product details
		 */
		public function checkForUpdates(onComplete:Function):void
		{
			if(_storeSupported)
			{
				var productIds:Vector.<String> = new Vector.<String>();
				for(var content : String in dlcContentDataDict)
				{	
					productIds.push(dlcContentDataDict[content].storeId);
				}
				var request:TransactionRequestData = TransactionRequestData.requestDetails(productIds,onTransactionComplete,onComplete);
				_productStore.requestTransaction(request);
			}
		}
		
		/**
		 * Handler for transaction state update from ProductStore via TransactionRequestData 
		 * @param request - TransactionRequestData conatins data about current transaction request
		 */
		private function onTransactionComplete( request:TransactionRequestData, requestState:String = "" ):void
		{
			if( !DataUtils.validString(requestState) ) { requestState = request.state; } 
			
			trace(this," :: onTransactionComplete:",request.type,"transaction ",requestState,"for product:",request.productId," message:",request.message,"errorType:",request.errorType);
			
			switch(request.type)
			{
				case TransactionRequestData.TYPE_PURCHASE:
				{
					onPurchaseTransactionComplete( request, requestState );
					break;
				}
				case TransactionRequestData.TYPE_RESTORE:
				{
					onRestoreTransactionComplete( request, requestState );
					break;
				}
				case TransactionRequestData.TYPE_DETAILS:
				{
					onDetailsTransactionComplete( request, requestState );
					break;
				}
				default:
				{
					break;
				}
			}
		}
		
		private function onPurchaseTransactionComplete( request:TransactionRequestData, requestState:String = "" ):void
		{
			var dlcContentData:DLCContentData = getContentByStoreId( request.productId );
			if( !dlcContentData )
			{
				shellApi.track("PurchaseFailed",  request.productId, "NotFound");
				
				trace("Error : DLCManager :: Attempted Purchase but DLCContentData not found for storeID: " +  request.productId );
				return;
			}
			
			if( requestState == TransactionRequestData.STATE_COMPLETED )
			{
				dlcContentData.purchased = true;
				saveDLCData();
				
				dlcContentData.onPurchaseCancel = null;
				dlcContentData.onPurchaseFail = null;
				if( dlcContentData.onPurchaseComplete != null )	
				{ 
					dlcContentData.onPurchaseComplete( dlcContentData, request );
					dlcContentData.onPurchaseComplete = null;
				}
				else { trace("Error : DLCManager :: " + TransactionRequestData.STATE_COMPLETED + " success handler was not specified"); }
			}
			else if( requestState == TransactionRequestData.STATE_CANCELLED )
			{
				shellApi.track("PurchaseCanceled",  request.productId, dlcContentData.contentId);
				
				dlcContentData.onPurchaseComplete = null;
				dlcContentData.onPurchaseFail = null;
				if( dlcContentData.onPurchaseCancel != null )	
				{ 
					dlcContentData.onPurchaseCancel( dlcContentData, request );
					dlcContentData.onPurchaseCancel = null;
				}
				else { trace("Error : DLCManager :: " + TransactionRequestData.STATE_COMPLETED + " cancel handler was not specified"); }
			}
			else if( requestState == TransactionRequestData.STATE_FAILED )
			{
				shellApi.track("PurchaseFailed",  request.productId, dlcContentData.contentId);
				
				dlcContentData.onPurchaseComplete = null;
				dlcContentData.onPurchaseCancel = null;
				if( dlcContentData.onPurchaseFail != null )	
				{ 
					dlcContentData.onPurchaseFail( dlcContentData, request );
					dlcContentData.onPurchaseFail = null;
				}
				else { trace("Error : DLCManager :: " + TransactionRequestData.STATE_COMPLETED + " failed handler was not specified"); }
			}
		}
		
		private function onRestoreTransactionComplete( request:TransactionRequestData, requestState:String = "" ):void
		{
			if ( requestState == TransactionRequestData.STATE_COMPLETED )
			{
				//shellApi.track("RestorePurchaseSucceeded");
				// NOTE :: restore complete handler called directly within TransactionRequestData, calls transactionRestored
			}
			if( requestState == TransactionRequestData.STATE_RESTORED_ALL )
			{
				shellApi.track("RestorePurchasesSucceeded");
				// NOTE :: restored all handler called directly within TransactionRequestData
			}
			else if ( requestState == TransactionRequestData.STATE_FAILED )
			{
				shellApi.track("TransactionFailed",request.productId, request.errorType + "_" + request.message);
				shellApi.logError( "RestoreTransactionFail : productId: " + request.productId + " " + request.errorType + "_" + request.message );
				// NOTE :: failed handler called directly within TransactionRequestData
			}
		}
		
		private function transactionRestored( request:TransactionRequestData, productId:String = "" ):void
		{
			// NOTE :: don't remove listener yet, continue listening until fail or all transactions are restored
			if( !DataUtils.validString(productId) ) { productId = request.productId; } 
			
			var dlcContentData:DLCContentData = getContentByStoreId( productId );
			if( dlcContentData )
			{
				dlcContentData.purchased = true;
				saveDLCData();				
			}
			else
			{
				trace(this," :: Could not find DLC for storeId: " + productId);
				shellApi.track("BadStoreIDAttempted",productId);
				// membership would not have a bundle so don't log an error trace out in scout for debugging
				//shellApi.logError( "Could not find DLC for storeId: " + productId );
				
				// TODO :: Do we really want to interrupt process? Will leave in for now for testing - Bard
				if( request.failCallback!= null )
				{
					request.state = TransactionRequestData.STATE_FAILED;
					request.errorType = "Purchase Restore Failed";
					request.message = "Could not find matching content between Store and App.";
					request.failCallback(request);
				}
			}
		}
		
		private function onDetailsTransactionComplete( request:TransactionRequestData, requestState:String = "" ):void
		{
			if( requestState == TransactionRequestData.STATE_COMPLETED )
			{
				for(var i : int = 0 ; i < request.productIds.length ; i++)
				{
					for(var prop:String in request.productId[i])
					{
						trace("property in product: "+prop+"  :"+request.productDetails[i]);
					}
				}
			}
			else{ trace(this,"onProductDetailsFailed"); }
		}
		
		//////////////////////////////// HELPERS ////////////////////////////////
		
		public function createDLCData( contentId:String, files:Array = null, packageType:String = "", contentType:String = "", prefix:String = "", validatorDelegate:IDLCValidator = null ):DLCContentData
		{
			var dlcData:DLCContentData = this.dlcContentDataDict[contentId];
			if( dlcData == null )
			{
				dlcData = new DLCContentData();
				dlcData.contentId = contentId;
				dlcData.purchased = false;
				dlcData.type = ( DataUtils.validString(contentId) ) ? contentType : TYPE_PRIMARY_CONTENT;
				dlcData.packagedFileState = ( DataUtils.validString(packageType) ) ? packageType : PackagedFileState.REMOTE_COMPRESSED;
				dlcData.networkPath = prefix;	
				if( validatorDelegate != null ) 
				{ 
					dlcData.validationRequired = true;
					dlcData.checkValidity = true;
					dlcData.validatorDelegate = validatorDelegate;
				}
				dlcData.files = files;
				
				this.addDLCContentData( dlcData );
			}
			return dlcData;
		}
		
		/**
		 * Force content's files to be installed/reinstalled 
		 * Adjust DLCFileData associated with DLCContentData to force an install
		 * @param contentId
		 */
		public function forceContentInstall( contentId:String ):void
		{
			var dlcData:DLCContentData = this.dlcContentDataDict[contentId];
			if( dlcData != null )
			{
				var i:int;
				var dlcFileData:DLCFileData;
				for (i = 0; i < dlcData.files.length; i++) 
				{
					dlcFileData = getDLCFileData(dlcData.files[i]);
					if( contentId )
					{
						dlcFileData.checkSum = "";	// NOTE :: We apply checkSum once zip has successfully loaded and decompressed
						dlcFileData.installed = false;
					}
					else
					{
						trace(this," :: Error :: forceContentInstall : DLCFileData coudl not be found for: " + dlcData.files[i] );
					}
				}
				
				if( dlcData.validationRequired ) 
				{ 
					dlcData.isValid = true;
					dlcData.checkValidity = true; 
				}
				saveDLCData();
			}
			else
			{
				trace(this," :: Error :: forceContentInstall : DLC could not be found for: " + contentId );
			}
		}
		
		/**
		 * Add DLCContentData to global data storage 
		 * @param dlcContent - DLCContentData to be added to global storage 
		 * @param replace - default to false, if true will replace existing DLCContentData with matching contentId
		 * @param save - default to true, whether profileM
		 * @return 
		 */
		public function addDLCContentData( dlcContent : DLCContentData, replace:Boolean = false, save:Boolean = true ) : Boolean
		{
			var success:Boolean = false;
			if( dlcContent )
			{
				if( shellApi.profileManager.globalData.dlc[dlcContent.contentId] )
				{
					if( replace )
					{
						shellApi.profileManager.globalData.dlc[dlcContent.contentId] = dlcContent;
						success = true;
					}
				}
				else
				{
					shellApi.profileManager.globalData.dlc[dlcContent.contentId] = dlcContent;
					success = true;
				}
			}
			
			if( success && save ) { saveDLCData(); }
			
			return success;
		}
		
		
		/**
		 * Helper function to set DLCContentData handlers
		 * @param dlcContentData
		 * @param onComplete
		 * @param onLoadProgress
		 * @param onError
		 * @param onStateChange
		 * @return 
		 */
		private function applyDLCHandlers(dlcData:DLCContentData, onComplete:Function = null, onLoadProgress:Function = null, onError:Function = null, onStateChange:Function = null, validatorDelegate:IDLCValidator = null ):DLCContentData
		{
			dlcData.fileIndex = 0;	// NOTE : Not sure if this is necessary, more of a safety - bard
			if( onComplete != null ) 		{ dlcData.onContentComplete = onComplete; }
			if( onLoadProgress != null ) 	{ dlcData.onLoadProgress = onLoadProgress; }
			if( validatorDelegate != null ) { dlcData.validatorDelegate = validatorDelegate; }
			
			if( dlcData.errorSignal == null ) { dlcData.errorSignal = new Signal( DLCContentData ); }
			if( onError != null )
			{
				dlcData.errorSignal.addOnce( onError );
			}
			
			if( dlcData.stateSignal == null ) { dlcData.stateSignal = new Signal( DLCContentData ); }
			if( onStateChange != null )
			{
				dlcData.stateSignal.add( onStateChange );
			}
			return dlcData;
		}
		
		/**
		 * Returns if corresponding DLC content's zipsum exists/matches currently store value. 
		 * @param contentId
		 * @return 
		 */
		public function isInstalled(contentId : String) : Boolean
		{
			var dlcData : DLCContentData = this.dlcContentDataDict[contentId];
			if(dlcData && dlcData.files.length > 0)
			{
				var fileId:String;
				var dlcFile:DLCFileData;
				for(var i : int = 0 ; i < dlcData.files.length ; i++)
				{
					fileId = dlcData.files[i];
					dlcFile = this.dlcFileDataDict[fileId];
					if( dlcFile )
					{
						if(this.dlcFileDataDict[fileId].checkSum != this._checkSumDictionary[fileId])
						{
							return false;
						}
					}
					else
					{
						trace("Error : DLCManager :: isInstalled : no DLCFileData of id: " + fileId + " for content: " +contentId)
					}
				}
			}
			else
			{
				trace("Error : DLCManager :: isInstalled : DlCData for "+contentId+" has no files!")
				return(false);
			}
			
			return true;
		}
		
		/**
		 * Returns package state of corresponding DLC content.
		 * Refer to PackagedFileState for valid states.
		 * @param content
		 * @return 
		 */
		public function getPackagedFileState(contentId : String) : String
		{
			if(dlcContentDataDict[contentId] != null)
			{
				return DLCContentData(this.dlcContentDataDict[contentId]).packagedFileState;
			}
			
			return(null);
		}
		
		/**
		 * Determines if there corresponding DLCContentData for the provided contentId.
		 * @param contentId - the island name assigned to the dlc packet
		 * @return 
		 */
		public function isContent( contentId : String) : Boolean
		{
			return (this.dlcContentDataDict[contentId] != null);
		}
		
		/**
		 * Update corresponding DLCFileData's installed value
		 * @param file - id of file, used to retrieve DLCFileData 
		 * @param value - 
		 */
		public function setFileInstalled(file:String, value:Boolean, save:Boolean = true) : void
		{
			if(dlcFileDataDict[file] != null)
			{
				DLCFileData(dlcFileDataDict[file]).installed = value;
				if( save ) { saveDLCData(); }
			}
			else
			{
				trace("DLCManager :: setFileInstalled : DLCFileData does not exist for " + file);
			}
		}
		
		/**
		 * Update corresponding DLCFileData 's checkSum value
		 * @param file - id of file, used to retrieve DLCFileData 
		 * @param value - 
		 */
		public function setCheckSum(fileId:String, checkSumValue:String, save:Boolean = true) : void
		{
			if(dlcFileDataDict[fileId] != null)
			{
				DLCFileData(dlcFileDataDict[fileId]).checkSum = checkSumValue;
				if( save ) { saveDLCData(); }
			}
			else
			{
				trace("DLCManager :: setCheckSum : " + fileId + " does not exist.");
			}
		}
		
		/**
		 * Update corresponding DLCFileData's purchased value
		 * @param file - id of file, used to retrieve DLCFileData 
		 * @param value - 
		 */
		public function setPurchased(content:String, isPurchased:Boolean, save:Boolean = true) : void
		{
			if(dlcContentDataDict[content] != null)
			{
				DLCContentData(this.dlcContentDataDict[content]).purchased = isPurchased;
				// TODO :: update local storage as well for content? - Bard
				if( save ) { saveDLCData(); }
			}
			else
			{
				trace("DLCManager :: setPurchased : " + content + " does not exist.");
			}
		}
		
		/**
		 * Determines if content is free
		 * @param content String
		 * @return Boolean
		 */
		public function isFree(contentId : String) : Boolean
		{
			if(dlcContentDataDict[contentId] != null)
			{
				return DLCContentData(this.dlcContentDataDict[contentId]).free;
			}
			else
			{
				trace("DLCManager :: isFree : " + contentId + " does not exist.");
				return(false);
			}
		}
		
		public function isPurchased(contentId : String) : Boolean
		{
			if(dlcContentDataDict[contentId] != null)
			{
				return DLCContentData(this.dlcContentDataDict[contentId]).purchased;
			}
			else
			{
				trace("DLCManager :: isPurchased : " + contentId + " does not exist.");
				return(false);
			}
		}
		
		/**
		 * Determines if corresponding content requires a purchase.I
		 * @param contentId - the island name assigned to the dlc packet
		 * @return 
		 */
		public function requiresPurchase( contentId : String) : Boolean
		{
			return (!this.isFree(contentId) && !this.isPurchased(contentId))
		}
		
		public function getContentByStoreId(storeId : String) : DLCContentData
		{
			var contentData:DLCContentData;
			for(var content : String in dlcContentDataDict)
			{
				contentData = dlcContentDataDict[content];
				if( contentData.storeId == storeId ){
					return contentData;
				}
			}
			return null;
		}
		
		public function getDLCContentData(contentId : String) : DLCContentData
		{
			return shellApi.profileManager.globalData.dlc[contentId] as DLCContentData;
		}
		
		/**
		 * Get store id of DLCCOntent  
		 * @param contentId
		 * @return 
		 * 
		 */
		public function getStoreID(contentId : String) : String
		{
			var dlcContent:DLCContentData = this.dlcContentDataDict[contentId];
			if( dlcContent )
			{
				return dlcContent.storeId;
			}
			return null;
		}
		
		public function getDLCFileData(fileId : String) : DLCFileData
		{
			return shellApi.profileManager.globalData.dlcFiles[fileId] as DLCFileData;
		}
		
		/**
		 * A <code>Dictionary</code> of DLCFileData that holds all of the info 
		 * regarding DLC files including their checksum and if they are installed.
		 */
		private function get dlcFileDataDict() : Dictionary
		{
			return shellApi.profileManager.globalData.dlcFiles;
		}
		
		/**
		 * A <code>Dictionary</code> of DLCContentData that holds all of the info 
		 * regarding DLC and whether content is downloaded, purchased, or free and a checkSum
		 * for validating zips with the backend.
		 */
		private function get dlcContentDataDict():Dictionary 
		{
			return shellApi.profileManager.globalData.dlc;
		}
		
		/**
		 *  Force ProfileManager to save current global data.
		 */
		private function saveDLCData() : void
		{
			shellApi.profileManager.saveGlobalData();
		}
		
		public function deleteContent(content:String, callback:Function):void
		{
			// TODO 
		}
		
		/**
		 * Remove content listed in global profile.
		 * WARNING :: As of yet does not remove the actual associated assets
		 * @param contentForRemoval - Array of content ids to remove from global profile
		 */
		public function removeDLCFromGlobalProfile(contentForRemoval:Array):void
		{
			var saveData:Boolean = false;
			
			// check every dictionary item
			var i:int;
			var j:int;
			var dlcData:DLCContentData;
			var contentId:String;
			for (i = 0; i < contentForRemoval.length; i++) 
			{
				// TODO :: We should really clear AppStorage as well
				contentId = contentForRemoval[i];
				dlcData = this.dlcContentDataDict[contentId];
				if( dlcData )
				{
					for (j = 0; j < dlcData.files.length; j++) 
					{
						delete this.dlcFileDataDict[dlcData.files[j]];
					}
					dlcData.destroy();
					delete this.dlcContentDataDict[contentId];
				}
				saveData = true;
			}
			
			if (saveData) { saveDLCData(); }
		}
		
		/**
		 * DEBUG USE : clears out all of the DLC stored in global data
		 */
		public function removeAllDLCFromGlobalProfile():void
		{
			var j:int;
			for each( var dlcData:DLCContentData in shellApi.profileManager.globalData.dlc )
			{
				// TODO :: We should really clear AppStorage as well
				for (j = 0; j < dlcData.files.length; j++) 
				{
					delete this.dlcFileDataDict[dlcData.files[j]];
				}
				dlcData.destroy();
				delete this.dlcContentDataDict[dlcData.contentId];
			}
			saveDLCData();
		}
		
		
		/////////////////////////////////// CONTENT VALIDITY /////////////////////////////////// 
		
		/**
		 * Set content validity, invalid content will not be used.
		 * Setting this also sets the checkValidiy flag to false.
		 * @param fileID name of file
		 * @param isInvalid - Boolean to make invalid or valid
		 */
		public function setContentValid( contentId:String, isValid:Boolean = true ):void
		{
			var dlcData:DLCContentData = getDLCContentData(contentId);
			if (dlcData != null)
			{
				dlcData.isValid = isValid;
				dlcData.checkValidity = false;
				saveDLCData();
			}
		}
		
		/**
		 * Return whether content should be blocked due to invalidness.
		 * If content is not found or is requires a fresh install, then it will not be blocked
		 * @param contentId - String id of content 
		 * @return boolean whether content should be blocked due to invalidness or not
		 */
		public function blockInvalidContent(contentId:String):Boolean
		{
			var dlcData:DLCContentData = getDLCContentData(contentId);
			if (dlcData != null)
			{
				// if content is flagged for validity check it shouldn't be block, since it attempting a validation
				if( !dlcData.checkValidity )
				{
					return !dlcData.isValid;
				}
			}
			return false;
		}
		
		/**
		 * Checks DLC content's checkValidity flag.
		 * If DLC content is not found for contentId, returns true.
		 */
		public function needsValidation(contentId:String):Boolean
		{
			var dlcData:DLCContentData = getDLCContentData(contentId);
			if (dlcData != null)
			{
				// if content is not set for validity check, we don't block content
				return dlcData.checkValidity;
			}
			return true;
		}
		
		/**
		 * Forces checkValidity flag to true for all DLCContentData that require validation
		 */
		public function forceValidation():void
		{
			for (var contentId:String in this.dlcContentDataDict)
			{
				var dlcData:DLCContentData = this.dlcContentDataDict[contentId];
				
				if( dlcData &&  dlcData.validationRequired )
				{
					dlcData.checkValidity = true;
				}
			}
			saveDLCData();
		}
		
		
		// TODO :: These signals can probably be managed through passed handlers instead
		//public var downloadStart:Signal = new Signal();
		//public var unzipStart:Signal = new Signal();
		public var onDownloadCancel:Signal = new Signal();
		
		public function get productStore():IProductStore
		{
			return _productStore;
		}
		
		private var _storeSupported : Boolean = false;
		public function isStoreSupported() : Boolean { return _storeSupported; }
		private var _productStore :IProductStore;
		private var _isLoading:Boolean = false;
		
		/** queue of content ids requesting load/decompression */
		private var _contentQueue:Vector.<DLCContentData> = new Vector.<DLCContentData>();
		
		/** Dictionary of zipCheckSum Strings, using file id as key */
		private var _checkSumDictionary:Dictionary;
		
		private const BAD_STORE_ID:String = " bad storeID ";
		
		public static var CONTENT_LOADING:String = "content_loading";
		public static var CONTENT_LOADED:String = "content_loaded";
		public static var CONTENT_INSTALLING:String = "content_installing";
		public static var CONTENT_INSTALLED:String = "content_installed";
		
		public static var TYPE_PRIMARY_CONTENT:String = "primary_content";
		public static var TYPE_SECONDARY_CONTENT:String = "secondary_content";
		public static var TYPE_BUNDLE:String = "bundle_content";
	}
}