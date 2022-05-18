package game.scene.template
{
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	
	import engine.group.DisplayGroup;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.data.dlc.DLCContentData;
	import game.data.dlc.PackagedFileState;
	import game.data.dlc.TransactionRequestData;
	import game.managers.DLCManager;
	import game.ui.elements.ProgressBox;
	import game.util.DataUtils;
	
	import org.assetloader.signals.ProgressSignal;
	import org.osflash.signals.Signal;
	
	/**
	 * Handles 'getting' content.
	 * @author umckiba
	 * 
	 */
	public class ContentRetrievalGroup extends Group
	{
		public function ContentRetrievalGroup()
		{
			super();
			super.id = GROUP_ID;
			processComplete = new Signal( Boolean, String );
		}
		
		override public function destroy():void
		{
			processComplete.removeAll();
			processComplete = null;

			super.destroy();
		}
		
		/**
		 * Setup group to manage content purchase/download.
		 * If specified group can create a popup that shows progress and state of content retrieval
		 * @param parentGroup - group this group will be added to
		 * @param addPopup - flag determining if a popup for progress should be created
		 * @param popupContainer - DisplayObjectContainer that popup will be placed within, if not specified uses groupConatiner of popupParentGroup
		 * @param popupParentGroup - group that popup will be added to, if not specified will use parentGroup
		 */
		public function setupGroup( parentGroup:Group, addPopup:Boolean = false, popupContainer:DisplayObjectContainer = null, popupParentGroup:DisplayGroup = null ):void
		{
			parentGroup.addChildGroup( this );

			// if createPopup is true, then create a popup to display content progress
			if( addPopup )
			{
				if( !popupParentGroup )	
				{ 
					if( parentGroup is DisplayGroup )
					{
						popupParentGroup = parentGroup as DisplayGroup;
					}
					else
					{
						trace( "Error :: ContentRetrievalGroup :: setupGroup : " + parentGroup + " must extend DisplayGroup if creating a popup."); 
						return;
					}
				}
				
				if( popupContainer == null )
				{
					popupContainer = popupParentGroup.groupContainer;
				}
				
				_hasPopup = addPopup;
				_popupParentGroup = popupParentGroup;
				_popupContainer = popupContainer;
			}
		}

		////////////////////////////////////////////////// PURCHASE CONTENT //////////////////////////////////////////////////
		
		public function purchaseContent( contentId:String, contentType:String, downloadAfterPurchase:Boolean = false ):void
		{
			if( startProcess("content purchase") )	// prevent this from getting spammed
			{
				//var localZip:Boolean = (super.shellApi.dlcManager.getPackagedFileState(contentId) == PackagedFileState.LOCAL_COMPRESSED);
				var progressState:String;
				var message:String;
				var title:String;

				if( !AppConfig.iapOn )
				{
					// set UI variables
					progressState = ProgressBox.STATE_NONE;
					message = "Purchases have not been enabled.";
					title = "Purchasing Disabled";
					if( _hasPopup )	{ setProgressBox( progressState, message, title );}
					
					endProcess();	// end process, since iap is off
				}
				//else if(super.shellApi.networkAvailable() || localZip)
				else if(super.shellApi.networkAvailable())
				{
					trace("ContentRetrievalGroup : attempt purchase for content: " + contentId);
					
					// set values for later reference
					_currentContentId = contentId;
					_currentContentType = contentType;
					
					// set UI variables
					progressState = ProgressBox.STATE_WAITING;
					message = "Purchasing " + contentType + "...";
					title = "Purchasing " + contentType;				
					if( _hasPopup )	{ setProgressBox( progressState, message, title );}
					
					// attempt purchase, if successful & downloadAfterPurchase = true start download
					var completeMethod:Function = ( downloadAfterPurchase ) ? Command.create(this.purchaseCompleted, true ) : this.purchaseCompleted;
					trace(completeMethod);
					super.shellApi.dlcManager.attemptPurchase( contentId, completeMethod, purchaseCancelled, purchaseFailed );
				}
				else
				{	
					// set UI variables
					progressState = ProgressBox.STATE_NONE;
					message = String("You must be connected to the internet\nfor " + contentType + " purchases");
					title = "No Connection";
					if( _hasPopup )	{ setProgressBox( progressState, message, title );}
					
					endProcess();	// end process, since network is inactive and download was required
				}
			}
		}
		
		protected function purchaseCompleted( dlcData:DLCContentData = null, request:TransactionRequestData = null, downloadAfterPurchase:Boolean = false ):void
		{
			if( !downloadAfterPurchase )
			{
				if( _hasPopup )
				{
					if( request && AppConfig.debug ){
						// FOR TESTING :: Get more accurate failure messaging
						setProgressBox( ProgressBox.STATE_NONE, request.message, request.errorType );
					}else{
						setProgressBox( ProgressBox.STATE_NONE, "Your purchase was made!", "Purchase Completed" );
					}
				}
				
				endProcess( true );
			}
			else
			{
				trace(this," :: onContentPurchased : will now begin download process.");
				_inProcess = false;	// NOTE :: set back to false, so that downloadContent doesn't get blocked
				downloadContent( dlcData.contentId, _currentContentType, dlcData );
			}
		}
		
		protected function purchaseCancelled( dlcData:DLCContentData = null, request:TransactionRequestData = null ):void
		{
			//_inProcess = false;
			if( _hasPopup )
			{
				setProgressBox( ProgressBox.STATE_NONE, "You have cancelled the purchase.", "Purchase Cancelled" );
			}
			endProcess();
		}
		
		protected function purchaseFailed( dlcData:DLCContentData = null, request:TransactionRequestData = null ):void
		{
			//_inProcess = false;
			if( _hasPopup )
			{
				if( request && AppConfig.debug ){
					// FOR TESTING :: Get more accurate failure messaging
					setProgressBox( ProgressBox.STATE_NONE, request.message, request.errorType );
				}else{
					setProgressBox( ProgressBox.STATE_NONE, "The purchase process has failed,\nplease try again later.", "Purchase Failed" );
				}
			}
			endProcess();
		}
		
		////////////////////////////////////////////////// DOWNLOAD CONTENT //////////////////////////////////////////////////
		
		/**
		 * Download content, manages popup display for process if popup is in use.
		 * Necessary handlers should be applied to the DLCContentData prior to calling this method.
		 * This Class and its methods are generally for managing UI display for the DLC & Purchase process
		 * @param contentId
		 * @param contentType
		 * @param contentData
		 */
		public function downloadContent( contentId:String = "", contentType:String = "", contentData:DLCContentData = null  ):void
		{
			if( startProcess("content download") )	// prevent this from getting spammed
			{
				if( DataUtils.validString(contentId) ) 		{ _currentContentId = contentId; }
				if( DataUtils.validString(contentType) ) 	{ _currentContentType = contentType; }
				
				var dlcManager:DLCManager = super.shellApi.dlcManager;
				var localZip:Boolean = (dlcManager.getPackagedFileState(_currentContentId) == PackagedFileState.LOCAL_COMPRESSED);
				var message:String;
				
				if( dlcManager.blockInvalidContent(contentId) )
				{
					message = "Errors found, unable to load content.\rTry updating to latest version of App.";
					setProgressBox( ProgressBox.STATE_NONE, message, "Error" );
					endProcess();
				}
				else
				{
					if(super.shellApi.networkAvailable() || localZip)
					{
						if( contentData == null )
						{
							//if(super.shellApi.dlcManager.getContent(this.pageXML.island, onContentDownloaded, onContentUnzipped, onContentProgress, onContentError))
							super.shellApi.dlcManager.loadContentById( _currentContentId, onContentDownloaded, onContentProgress, onContentError, onContentUpdate );
						}
						else
						{
							super.shellApi.dlcManager.loadContentByData( contentData, onContentDownloaded, onContentProgress, onContentError, onContentUpdate );
						}
						
						if( _hasPopup )
						{
							// setup UI for downloading
							message = "Downloading " + _currentContentType + "...";
							setProgressBox( ProgressBox.STATE_LOADING, message, _currentContentType + " Setup", "Cancel", cancelDownload, localZip );
						}
					}
					else
					{	
						message = "You must be connected to the internet to download the required update for this " + _currentContentType + ".";
						setProgressBox( ProgressBox.STATE_NONE, message, "No Connection" );
						endProcess();
					}
				}
			}
		}
		
		private function cancelDownload(...args):void
		{
			super.shellApi.dlcManager.cancelAllContentDownloads();
			endProcess();
		}
		
		protected function onContentProgress(progress:ProgressSignal):void
		{
			if( _progressPopup )
			{
				_progressPopup.progressPercent = progress.progress / 100;
			}
		}
		
		protected function onContentDownloaded( ...args ):void
		{
			// NOTE :: This assumes an island load, which may assumes too much
			if( _progressPopup )
			{
				_progressPopup.disableButton();
				_progressPopup.message = "Loading " + _currentContentType + "...";
				// NOTE :: popup remains open
			}
			
			endProcess( true );
		}

		protected function onContentError( purchase:Boolean = false, cancel:Boolean = false):void
		{
			if(cancel)
			{
				trace(this, "onContentError cancel:",cancel);
				if( _progressPopup )
				{
					_progressPopup.close();
				}
			}
			else
			{
				var message:String;
				var title:String;
				if(super.shellApi.networkAvailable())
				{
					var action : String = (purchase) ? "retrieving" : "downloading";
					message = "Error " + action + " this " + _currentContentType + ".\rPlease try again later.";
					title = "Sorry";
				}
				else
				{
					message = "You must be connected to the internet to download the required update for this " + _currentContentType + ".";
					title = "Network Unavailable";
				}
				
				if( _hasPopup )
				{
					setProgressBox( ProgressBox.STATE_NONE, message, title);
				}
			}
			endProcess();
		}
		
		/**
		 * Handler for dispatch associated with DLC's state change.
		 * Used to determien where in the download process the content, used to update UI. 
		 * @param contentData
		 */
		private function onContentUpdate( contentData:DLCContentData ):void
		{
			trace(this," : onContentUpdate : " + contentData.state);
			switch(contentData.state)
			{
				case DLCManager.CONTENT_LOADING:
				{
					downloadStarted( contentData.fileIndex, contentData.files.length );
					break;
				}
					
				case DLCManager.CONTENT_LOADED:
				{
					break;
				}
					
				case DLCManager.CONTENT_INSTALLING:
				{
					installStarted( contentData.fileIndex, contentData.files.length );
					break;
				}
					
				case DLCManager.CONTENT_INSTALLED:
				{
					break;
				}
					
				default:
				{
					break;
				}
			}
		}

		
		////////////////////////////////////////////////// PROGRESS UI //////////////////////////////////////////////////

		/**
		 * Updates progress bar, creating a new instance if none is present. 
		 * @param state - the state of the progress bar, states are stored as static consts in ProgressBox (STATE_NONE, STATE_WAITING, STATE_LOADING, STATE_COMPLETE)
		 * @param message - status message
		 * @param title - title header
		 * @param buttonText - text displayed on button
		 * @param closeHandler - Function called when ProgressBox is removed.
		 * @param disableButton - flag to put button into a disabled stated
		 * @return 
		 */
		protected function setProgressBox( state:String = ProgressBox.STATE_NONE, message:String = "", title:String = "", buttonText:String = "", closeHandler:Function = null, disableButton:Boolean = false ):void
		{
			if( _progressPopup == null )
			{
				_progressPopup = new ProgressBox( _popupContainer );
				_progressPopup.setup( state, title, message, true, true, buttonText );
				_popupParentGroup.addChildGroup(_progressPopup);
			}
			else
			{
				if( DataUtils.validString(message) )	{ _progressPopup.message = message; }
				if( DataUtils.validString(title) )		{ _progressPopup.title = title; }
				if( DataUtils.validString(buttonText) )	{ _progressPopup.buttonText = buttonText; }
				_progressPopup.setState( state, true );
			}

			_progressPopup.disableButton( disableButton );

			_progressPopup.popupRemoved.removeAll();
			if( closeHandler ) { _progressPopup.popupRemoved.addOnce( closeHandler ); }
			_progressPopup.popupRemoved.addOnce( removePopupReference );
		}
		
		protected function removePopupReference():void
		{
			_progressPopup = null;
		}
		
		/**
		 * Force close progress popups if it exists 
		 */
		public function closePopup():void
		{
			if( _progressPopup )
			{
				_progressPopup.close();
				_progressPopup = null;
			}
		}

		/**
		 * Updates the message within the loading bar, indicates which file is being downloaded.
		 * @param fileNumber
		 * @param totalFiles
		 */
		private function downloadStarted(fileNumber:int, totalFiles:int):void
		{
			if( _progressPopup )
			{
				_progressPopup.resetProgressBar();
				_progressPopup.disableButton(false);
				_progressPopup.message = "Downloading update " + fileNumber + " of " + totalFiles;
			}
		}
		
		/**
		 * Updates the message within the loading bar, indicates which file is being installed.
		 * @param fileNumber
		 * @param totalFiles
		 */
		private function installStarted(fileNumber:int, totalFiles:int):void
		{
			if( _progressPopup )
			{
				_progressPopup.disableButton(true);
				_progressPopup.message = "Installing update " + fileNumber + " of " + totalFiles;
			}
		}

		////////////////////////////////////////////////// PROCESS //////////////////////////////////////////////////
		
		/**
		 * Start DLC process, used to make sure attempts one process at a time
		 * @param message - String used for debugging, let's us know which process has started
		 * @return - returns true if process not already active
		 */
		private function startProcess( message:String = "" ):Boolean
		{
			if( !_inProcess )
			{
				trace(this,"startProcess : " + message);
				_inProcess = true;
				return true;
			}
			else
			{
				trace(this,"startProcess : denied, already in process");
				return false;
			}
		}
		
		/**
		 * End DLC process, dispatches processComplete Signal if processing was active
		 */
		private function endProcess( success:Boolean = false ):void
		{
			if( _inProcess )
			{
				processComplete.dispatch( success, _currentContentId );
			}
			_inProcess = false;
		}
		
		////////////////////////////////////////////////// BUTTON HELPERS //////////////////////////////////////////////////
		
		public static const GROUP_ID:String = "contentRetrievalGroup";
		
		/** Dispatched when process has finished, dispatches with params [success:Boolean, content:String] */
		public var processComplete:Signal;
		
		private var _inProcess:Boolean = false;
		private var _currentContentId:String;
		private var _currentContentType:String;
		
		// UI specific
		private var _hasPopup:Boolean = false;
		private var _progressPopup:ProgressBox;
		private var _popupParentGroup:DisplayGroup;
		private var _popupContainer:DisplayObjectContainer;
		
	}
}