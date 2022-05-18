package game.data.dlc
{
	/**
	 * Class used to pass and receive transaction request data to and from classes implementing IProductStore.
	 * Holds type of transaction and necessary data, as well as handlers.
	 * Static 'request...' helper functions can be used to create TransactionRequestData for specific request types.
	 * @author umckiba
	 */
	public class TransactionRequestData
	{
		public function TransactionRequestData()
		{
		}
		
		/**
		 * Create request to purchased a product
		 * @param productId
		 * @param onComplete
		 * @param onCancel
		 * @param onFail
		 * @param host
		 * @return 
		 */
		public static function requestPurchase( productId:String = "", onTransactionComplete:Function = null, onComplete:Function = null, onCancel:Function = null, onFail:Function = null, host:String = "" ):TransactionRequestData
		{
			var request:TransactionRequestData = new TransactionRequestData();
			request.type = TransactionRequestData.TYPE_PURCHASE;
			request.productId = productId;
			request.transactionComplete = onTransactionComplete;
			request.failCallback = onFail;
			request.completeCallback = onComplete;
			request.cancelCallback = onCancel;
			request.host = host;
			return request;
		}
		
		/**
		 * Create request to restore purchased products
		 * @param onRestoredAll
		 * @param onFail
		 * @param onRestore
		 * @param host
		 * @return 
		 */
		public static function requestRestoreAll( onTransactionComplete:Function = null, onRestoredAll:Function = null, onFail:Function = null, onRestore:Function = null, host:String = "" ):TransactionRequestData
		{
			var request:TransactionRequestData = new TransactionRequestData();
			request.type = TransactionRequestData.TYPE_RESTORE;
			request.transactionComplete = onTransactionComplete;
			request.restoredAllCallback = onRestoredAll;
			request.failCallback = onFail;
			request.completeCallback = onRestore;
			request.host = host;
			request.productIds = new Vector.<String>();
			return request;
		}
		
		/**
		 * Create request for details for listed products 
		 * @param productIds
		 * @param onComplete
		 * @param onFail
		 * @param host
		 * @return 
		 */
		public static function requestDetails( productIds:Vector.<String> = null, onTransactionComplete:Function = null, onComplete:Function = null, onFail:Function = null, host:String = "" ):TransactionRequestData
		{
			var request:TransactionRequestData = new TransactionRequestData();
			request.type = TransactionRequestData.TYPE_DETAILS;
			request.transactionComplete = onTransactionComplete;
			request.productIds = productIds;
			request.failCallback = onFail;
			request.completeCallback = onComplete;
			request.host = host;
			return request;
		}
		
		// provided
		public var type:String;
		public var productId : String;
		public var productIds : Vector.<String>;
		public var host:String;
		
		// returned
		public var state:String;
		public var productDetails:Array;
		public var errorType:String;
		public var message:String;
		public var transactionData:Object;			// an associative array of key-value pairs providing supplemental information about the transaction results
		
		
		/** Function called for response of any of transaction type, parameters returned are [ TransactionRequestData, currentState:String ] */
		public var transactionComplete:Function;
		
		public var completeCallback:Function;	
		public var cancelCallback:Function;		
		public var failCallback:Function;
		public var restoredAllCallback:Function;	
		
		static public var TYPE_PURCHASE:String 		= "purchase";
		static public var TYPE_RESTORE:String 		= "restore";
		static public var TYPE_DETAILS:String 		= "details";
		
		static public var STATE_FAILED:String 		= "failed";
		static public var STATE_CANCELLED:String 	= "cancelled";
		static public var STATE_COMPLETED:String 	= "completed";
		static public var STATE_RESTORED_ALL:String = "restored_all";
		
		public function sendState( transactionState:String ):void
		{
			this.state = transactionState;
			if( transactionComplete ) { transactionComplete( this, this.state ); }
		}
		
		public function failed():void
		{
			this.state = STATE_FAILED;
			if( transactionComplete ) { transactionComplete( this, STATE_FAILED ); }
			if( failCallback ) { failCallback( this ); }
		}
		
		public function cancelled():void
		{
			this.state = STATE_CANCELLED;
			if( transactionComplete ) { transactionComplete( this, STATE_CANCELLED ); }
			if( cancelCallback )	{ cancelCallback( this ); }
		}
		
		public function completed():void
		{
			this.state = STATE_COMPLETED;
			if( transactionComplete ) { transactionComplete( this, STATE_COMPLETED ); }
			if( completeCallback ) { completeCallback( this, this.productId ); }
		}
		
		public function restoredAll():void
		{
			this.state = STATE_RESTORED_ALL;
			if( transactionComplete ) { transactionComplete( this, STATE_RESTORED_ALL ); }
			if( restoredAllCallback ) 	{ restoredAllCallback( this ); }
		}
		
		public function toString():String
		{
			var str:String = "[TransactionRequestData";
			str += " type:" + type + " state:" + state + " productId:" + productId;
			str += " errorType:" + errorType + " message:" + message + " host:" + host;
			return str + ']';
		}
	}
}
