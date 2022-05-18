package game.data.dlc
{
	import game.managers.interfaces.IDLCValidator;
	
	import org.osflash.signals.Signal;

	public class DLCContentData
	{
		public var contentId : String = "";
		public var free : Boolean = false;
		public var purchased : Boolean = false;
		public var storeId : String;
		public var type : String;
		
		/** Flag indicating that the content associated with this DLCContentData is one that requires a validation */
		public var validationRequired: Boolean = false;
		/** Flag used to determine if a validation check should happen */
		public var checkValidity : Boolean = false;
		/** Flag indicating that the content associated with this DLCContentData has failed its validation test */
		public var isValid : Boolean = true;
		
		public var errorSignal:Signal = new Signal(DLCContentData);
		public var stateSignal:Signal = new Signal(DLCContentData);
		
		private var _state:String = "";
		public function get state():String { return _state; }
		public function set state( value:String ):void
		{
			if( _state != value )
			{
				_state = value;
				if( stateSignal != null )
				{
					stateSignal.dispatch( this ); 
				}
			}
		}
		
		/** 
		 * List of file ids as Strings, file id correspond to content ultimately retrived as zips.  
		 * File ids should NOT have .zip as a suffix
		 */
		public var files:Array;					
		/** Refer to PackagedFileState for valid values ( localCompressed, remoteCompressed, uncompressed ) */
		public var packagedFileState:String;
		/** Path to where content is store, if defined a default will be used */
		public var networkPath:String = "";
		
		/** Used to track file loading progress */
		public var fileIndex:int = 0;
		public var currentFile:String;

		public var onContentComplete:Function; 
		public var onLoadProgress:Function;
		public var onDownloadCancel:Function;
		
		/** Delegate class used to validate content, must implement IDLCValidator */
		public var validatorDelegate:IDLCValidator;
		//public var onContentError:Function;
		
		public var onPurchaseComplete:Function;	// first parameter will be this DLCContentData
		public var onPurchaseCancel:Function;	// first parameter will be this DLCContentData
		public var onPurchaseFail:Function;		// first parameter will be this DLCContentData
		
		/**
		 *  Reset values associated with the loading the content
		 */
		public function reset():void
		{
			//onContentComplete = null;	// QUESTION :: Don't want to reset this as well?
			onLoadProgress = null;
			onDownloadCancel = null;
			onPurchaseComplete = null;
			onPurchaseCancel = null;
			onPurchaseFail = null;
			fileIndex = 0;
			currentFile = "";
			
			if( stateSignal != null ) 
			{ 
				stateSignal.removeAll(); 
			}
			
			if( errorSignal != null ) 
			{ 
				errorSignal.removeAll();
			}
		}
		
		public function destroy():void
		{
			reset();
			validatorDelegate = null;
			onContentComplete = null;
			files = null;
			stateSignal = null;
			errorSignal = null;
		}

	}
}