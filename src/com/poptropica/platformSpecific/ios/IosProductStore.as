package com.poptropica.platformSpecific.ios
{
	import com.milkmangames.nativeextensions.ios.StoreKit;
	import com.milkmangames.nativeextensions.ios.StoreKitProduct;
	import com.milkmangames.nativeextensions.ios.events.StoreKitErrorEvent;
	import com.milkmangames.nativeextensions.ios.events.StoreKitEvent;
	import com.poptropica.AppConfig;
	import com.poptropica.interfaces.IProductStore;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.Timer;
	
	import engine.util.Command;
	
	import game.data.dlc.TransactionRequestData;
	import game.data.profile.ProfileData;
	import game.util.Base64;
	
	public class IosProductStore implements IProductStore
	{
		private const RECEIPT_VERIFICATION_CALL:String = "/interface/call.php?class=PopAppPurchase&method=VerifyReceipt";
		private const TRANSACTION_TIMER_DELAY : int = 10000;
		
		private var _verifyReceipt:Boolean = false;
		
		private var _restoreCount : int = 0;
		private var _host:String
		private var _vendorID : String;
		private var _transactionTimer :Timer;
		private var _transactionCount : Array;
		
		private var _onTransactionFailed : Function;
		private var _onTransactionFinished : Function;
		
		private var _request : TransactionRequestData;
		
		private var _profile:ProfileData;
		
		public function IosProductStore()
		{
			if (!this.isSupported())
			{
				trace(this,"IosProductStore purchases is not supported on this platform");
				return;
			}
			
			trace(this,"initializing IosProductStore");	
			StoreKit.create();
			trace(this,"IosProductStore Initialized");
			
			if (!this.isAvailable())
			{
				//Should we alert user that they cannot make purchases?
				trace(this,"App Store purchasing is disabled on this device.");
				//return;
			}
			
			// set this mode & define vendor id so we can verify purchases through own own servers
			StoreKit.storeKit.setManualTransactionMode(_verifyReceipt);
			this._transactionCount = new Array();
		}
		
		public function setProfile(profile:ProfileData):void
		{
			_profile = profile;
		}
		
		public function setUpHost(host:String):void
		{
			_host = host.replace("www","store");
		}
		
		public function isSupported():Boolean
		{
			trace(this,"isSupported()",StoreKit.isSupported());
			return StoreKit.isSupported();
		}
		
		public function isAvailable():Boolean
		{
			trace(this,"isAvailable()",StoreKit.storeKit.isStoreKitAvailable());
			return StoreKit.storeKit.isStoreKitAvailable();
		}
		
		public function setManualMode(manaul:Boolean):void
		{
			_verifyReceipt = manaul;
			StoreKit.storeKit.setManualTransactionMode(_verifyReceipt);
		}
		
		public function requestTransaction( request:TransactionRequestData ):void
		{
			_request = request;
			trace(this," :: requestTransaction : " + request.toString() );
			
			switch(request.type)
			{
				case TransactionRequestData.TYPE_DETAILS:
				{
					getProductDetails();
					break;
				}
					
				case TransactionRequestData.TYPE_PURCHASE:
				{
					getNonConsumableProduct();
					break;
				}
					
				case TransactionRequestData.TYPE_RESTORE:
				{
					restoreTransactions();
					break;
				}
					
				default:
				{
					break;
				}
			}
		}
		
		////////////////////////////////////// PRODUCT DETAILS //////////////////////////////////////
		
		/**
		 * Request details from AppleStore for listed products 
		 */
		private function getProductDetails() : void
		{
			trace(this,"getProductDetails()");
			
			StoreKit.storeKit.addEventListener(StoreKitEvent.PRODUCT_DETAILS_LOADED,productDetailsSucceeded);
			StoreKit.storeKit.addEventListener(StoreKitErrorEvent.PRODUCT_DETAILS_FAILED,productDetailsFailed);
			StoreKit.storeKit.loadProductDetails(_request.productIds);
		}
		
		public function productDetailsSucceeded(event:StoreKitEvent):void
		{
			trace(this,"productDetailsSucceeded()",event);
			
			_request.productDetails = new Array();
			var i:uint=0;
			while(event.validProducts && i < event.validProducts.length)
			{
				var product:StoreKitProduct = event.validProducts[i];
				trace( productDetailsToString( product ) );
				
				//converts Ios Specific products to generic objects so DLCManager has loose coupling with store code. 
				_request.productDetails.push(product as Object);
				i++;
			}
			
			removeProductDetailListeners();
			_request.completed();
		}
		
		private function productDetailsToString( product:StoreKitProduct ):String
		{
			var string:String = "";
			string += "title : "+product.title;
			string += "\rdescription: "+product.description;
			string += "\ridentifier: "+product.productId;
			string += "\rpriceLocale: "+product.localizedPrice;
			string += "\rlocalizedPrice  "+product.localizedPrice;
			string += "\rprice :"+product.price;
			return string
		}
		
		public function productDetailsFailed(event:StoreKitErrorEvent):void
		{
			trace(this,"productDetailsFailed()",event.errorId, event.text);
			
			removeProductDetailListeners();
			_request.message = event.text;
			_request.failed();
		}
		
		private function removeProductDetailListeners():void
		{
			StoreKit.storeKit.removeEventListener(StoreKitEvent.PRODUCT_DETAILS_LOADED,productDetailsSucceeded);
			StoreKit.storeKit.removeEventListener(StoreKitErrorEvent.PRODUCT_DETAILS_FAILED,productDetailsFailed);
		}
		
		////////////////////////////////////// PRODUCT PURCHASE //////////////////////////////////////
		
		public function getConsumableProduct(id : String, callback : Function, cancelCallback:Function, failCallback:Function, host : String):void
		{
			trace(this,"getConsumableProduct()",id);
			//no IOS implementation;
		}
		
		/**
		 * Attempts a purchase.
		 * Based on type of StoreKitEvent returned purchaseTransactionSucceeded, purchaseTransactionCanceled, or purchaseTransactionFailed will be called.
		 * @param id - store id of product to be purchase
		 * @param callback - Function called if purchase is successful
		 * @param cancelCallback - Function called if purchase cancelled by user
		 * @param failCallback - Function called if purchase fails
		 * @param host - server to contact when verifying purchase receipt
		 */
		private function getNonConsumableProduct():void
		{
			trace(this,"getNonConsumableProduct : for product id:",_request.productId);
			
			_onTransactionFailed = onPurchaseFailed;
			_onTransactionFinished = onPurchaseFinished;
			
			// set up listeners for StoreKit
			addPurchaseListeners();
			StoreKit.storeKit.purchaseProduct(_request.productId);
		}
		
		/**
		 * Called once purchase has finished, this includes Apple purchase approval and receipt verification via our servers.
		 * This does not include purchase cancellation, which is user driven.
		 * @param productId
		 */
		private function onPurchaseFinished( productId:String ):void
		{
			trace(this," :: onPurchaseFinished : for product id: " + productId );
			// purchase is complete and verfied
			removePurchaseListener();
			
			_request.productId = productId;
			_request.errorType = "Purchase Completed";
			_request.message = "Purchase has successfully completed";
			_request.completed();
		}
		
		/**
		 * Called if purchase fails at any point during process
		 * @param productId
		 * @param title
		 * @param message
		 */
		private function onPurchaseFailed( productId:String, type:String = "", message = "" ):void
		{
			trace(this," :: onPurchaseFailed : for product id:",productId,"type:",type,"message:",message);
			
			// purchase failed in some way
			removePurchaseListener();
			
			_request.productId = productId;
			_request.errorType = type;
			_request.message = message;
			_request.failed();
		}
		
		private function addPurchaseListeners():void
		{
			trace(this, ":: addPurchaseListeners()");
			StoreKit.storeKit.addEventListener(StoreKitEvent.PURCHASE_SUCCEEDED,this.purchaseSucceeded);
			StoreKit.storeKit.addEventListener(StoreKitEvent.PURCHASE_CANCELLED,this.purchaseCancelled);
			StoreKit.storeKit.addEventListener(StoreKitErrorEvent.PURCHASE_FAILED,this.purchaseFailed);
		}

		private function removePurchaseListener():void
		{
			trace(this, ":: removePurchaseListeners()");
			StoreKit.storeKit.removeEventListener(StoreKitEvent.PURCHASE_SUCCEEDED,this.purchaseSucceeded);
			StoreKit.storeKit.removeEventListener(StoreKitEvent.PURCHASE_CANCELLED,this.purchaseCancelled);
			StoreKit.storeKit.removeEventListener(StoreKitErrorEvent.PURCHASE_FAILED,this.purchaseFailed);
		}

		/**
		 * Listener for StoreKitEvent.PURCHASE_SUCCEEDED, returned on purchase or restore purchase requests
		 * @param storeKitEvent
		 */
		private function purchaseSucceeded(storeKitEvent:StoreKitEvent):void
		{
			trace(this," :: purchaseTransactionSucceeded : storeKitEvent: ",storeKitEvent.productId + " originalRequestId: " + _request.productId);
			
			if( _verifyReceipt )
			{
				// verify purchase with our own servers
				// NOTE :: We're skipping receipt verification for now, need to get a better handle of process before reintroducing
				this._transactionCount.length = 0;
				
				verifyReceipt( storeKitEvent );
				// don't start timer until receipt is ready
			}
			else if(storeKitEvent.productId == _request.productId)
			{
				manuallyFinishTransactions([storeKitEvent.transactionId]);
				_onTransactionFinished( storeKitEvent.productId );
			}
			else
			{
				trace("What you trying to pull you scoundrally dog");
			}
		}

		/**
		 * Called in case of StoreKitEvent.PURCHASE_FAILED
		 * @param event
		 */
		private function purchaseFailed(errorEvent:StoreKitErrorEvent):void
		{
			trace(this," :: purchaseFailed : storeKitEvent:",errorEvent);
			
			manuallyFinishTransactions([errorEvent.transactionId]);
			
			var message:String = errorEvent.text;
			if( !AppConfig.production ){ message += "\nError id " + errorEvent.errorId; }
			_onTransactionFailed( errorEvent.productId,"Apple Store Failure", message );
		}
		
		/**
		 * Called in case of StoreKitEvent.PURCHASE_CANCELLED
		 * @param event
		 */
		private function purchaseCancelled(storeKitEvent:StoreKitEvent):void
		{
			trace(this,"purchaseTransactionCanceled : storeKitEvent:",storeKitEvent);
			
			removePurchaseListener();
			manuallyFinishTransactions([storeKitEvent.transactionId]);
			
			_request.errorType = "Purchase Cancelled";
			_request.message = "Purchase was cancelled.";
			_request.cancelled();
		}
		
		///////////////////////////////////////// RESTORE PURCHASES /////////////////////////////////////////
		
		private function restoreTransactions() : void
		{
			trace(this,"restoreTransactions()");
			
			_restoreCount = 0;
			_transactionCount.length = 0;
			
			_onTransactionFinished = onRestorePurchaseFinished;
			_onTransactionFailed = onRestorePurchaseFailed;

			addTransactionRestoreListeners();
			StoreKit.storeKit.restoreTransactions();
		}
		
		/**
		 * Called when a transaction has been restored by Apple and verified by our servers
		 * @param productId
		 */
		private function onRestorePurchaseFinished( productId:String ):void
		{
			trace(this," :: onRestorePurchaseFinished : productId:",productId);
			
			// restore is complete and verified
			_request.productId = productId;
			_request.productIds.push( productId );
			_request.completed();
			
			// NOTE :: We're skipping receipt verification for now, need to get a better handle of process before reintroducing
			// Since we aren't waiting for receipt verification we can rely on the StoreKitEvent.TRANSACTIONS_RESTORED for completion
			if( _verifyReceipt )
			{
				_restoreCount--;
				if(_restoreCount == 0)
				{
					removeTransactionRestoreListener();
					_request.errorType = "Purchases Restored";
					_request.message = "Purchases have been restored.";
					_request.restoredAll();
				}
			}
		}
		
		private function onRestorePurchaseFailed( productId:String = "", type:String = "", message = ""):void
		{
			// purchase failed in some way
			trace(this," :: onRestorePurchaseFailed : for product id:",productId,"type:",type,"message:",message);
			
			// TODO :: If a single restore transaction fails, should we force failure for all?
			removeTransactionRestoreListener();

			_request.productId = productId;
			_request.errorType = type;
			_request.message = message;
			_request.failed();
		}

		private function addTransactionRestoreListeners():void
		{
			// For each previously completed transaction StoreKitEvent.PURCHASE_SUCCEEDED will be called
			StoreKit.storeKit.addEventListener(StoreKitEvent.PURCHASE_SUCCEEDED,restoreTransactionSucceeded);
			
			// TODO :: Not sure if PURCHASE_FAILED gets called or if only TRANSACTION_RESTORE_FAILED does? - bard
			StoreKit.storeKit.addEventListener(StoreKitErrorEvent.PURCHASE_FAILED,restoreTransactionFailed);
			
			// StoreKitEvent.TRANSACTIONS_RESTORE is fired when all previous purchases have finished firing StoreKitEvent.PURCHASE_SUCCEEDED
			StoreKit.storeKit.addEventListener(StoreKitEvent.TRANSACTIONS_RESTORED, restoreAllTransactionsSucceeded);
			
			// fired if there is an error during the process
			StoreKit.storeKit.addEventListener(StoreKitErrorEvent.TRANSACTION_RESTORE_FAILED, restoreAllTransactionFailed);
		}
		
		private function removeTransactionRestoreListener():void
		{
			StoreKit.storeKit.removeEventListener(StoreKitEvent.PURCHASE_SUCCEEDED,restoreTransactionSucceeded);
			StoreKit.storeKit.removeEventListener(StoreKitErrorEvent.PURCHASE_FAILED,restoreTransactionFailed);
			StoreKit.storeKit.removeEventListener(StoreKitEvent.TRANSACTIONS_RESTORED, restoreAllTransactionsSucceeded);
			StoreKit.storeKit.removeEventListener(StoreKitErrorEvent.TRANSACTION_RESTORE_FAILED, restoreAllTransactionFailed);
		}
		
		/**
		 * Listener for StoreKitEvent.PURCHASE_SUCCEEDED, returned on purchase or restore purchase requests
		 * @param storeKitEvent
		 */
		private function restoreTransactionSucceeded(storeKitEvent:StoreKitEvent):void
		{
			trace(this," :: restoreTransactionSucceeded : storeKitEvent:",storeKitEvent);
			
			// NOTE :: We're skipping receipt verification for now, need to get a better handle of process before reintroducing
			if( _verifyReceipt )
			{
				// verify purchase with our own servers
				// if purchase succeed is part of purchase restoration increment restoration count
				_restoreCount++;	// TODO :: Need a flag to know we are just waiting on verification?
				verifyReceipt( storeKitEvent ); // on verification complete restore next purchase
			}
			else
			{
				this.manuallyFinishTransactions( [storeKitEvent.productId] );
				_onTransactionFinished( storeKitEvent.productId );
			}
		}

		/**
		 * Called in case of StoreKitEvent.TRANSACTIONS_RESTORED, which is sent if restoration fails at any point
		 * @param event
		 */
		private function restoreAllTransactionsSucceeded(storeKitEvent:StoreKitEvent):void
		{
			trace(this," :: restoreAllTransactionsSucceeded : StoreKitEvent:",storeKitEvent.toString());

			// NOTE :: We're skipping receipt verification for now, need to get a better handle of process before reintroducing
			if( _verifyReceipt )
			{
				// Even if all StoreKitEvent.PURCHASE_SUCCEEDED have been fired we still need to wait for confirmation form our own server
				// Start timer once we know the last restore purchase has completed
				startVerificationTimer();
			}
			else
			{
				removeTransactionRestoreListener();
				_request.errorType = "Purchases Restored";
				_request.message = "Purchases have been restored.";
				_request.restoredAll();
			}
		}

		/**
		 * Called in case of StoreKitErrorEvent.TRANSACTION_RESTORE_FAILED
		 * @param event
		 */
		private function restoreAllTransactionFailed(storeKitErrorEvent:StoreKitErrorEvent):void
		{
			trace(this,"restoreAllTransactionFailed",storeKitErrorEvent.toString());
			_onTransactionFailed( storeKitErrorEvent.productId, "AppleStore Failure", storeKitErrorEvent.text );
		}
		
		/**
		 * TODO :: Not sure if restoreTransactionFailed would also be getting called in same event? Need to test if transactionRestoreFailed is necessary - bard
		 * Called in case of StoreKitEvent.PURCHASE_FAILED, returned on purchase or restore purchase requests
		 * @param event
		 */
		private function restoreTransactionFailed(storeKitErrorEvent:StoreKitErrorEvent):void
		{
			trace(this,"restoreTransactionFailed : StoreKitErrorEvent:",storeKitErrorEvent.toString());
			manuallyFinishTransactions([storeKitErrorEvent.transactionId]);
			
			// TODO :: Not sure if we should do any error handling here, or if it can be assumed that restoreAllTransactionFailed will be called as well
			//_onTransactionFailed( storeKitErrorEvent.productId, "AppleStore Failure", storeKitErrorEvent.text );
			
			/*
			removeTransactionRestoreListener();
			//removeTransactionID(storeKitEvent.productId);
			stopVerificationTimer();
			manuallyFinishTransactions([storeKitEvent.transactionId]);
			if( _failCallback != null){
			this._failCallback(storeKitEvent.productId,"AppleStoreFailure", storeKitEvent.text+" " +storeKitEvent.errorId);
			}
			*/
		}
		
		/////////////////////////////////// PURCHASE VERIFICATION ///////////////////////////////////
		
		private function startVerificationTimer():void
		{
			trace(this," :: verifyReceipt : start timer for verification call")
			this._transactionTimer = new Timer(TRANSACTION_TIMER_DELAY, 1);
			this._transactionTimer.addEventListener(TimerEvent.TIMER_COMPLETE, verificationTimedOut);
			this._transactionTimer.start();
		}
		
		private function stopVerificationTimer() : void
		{
			if( _transactionTimer )
			{
				this._transactionTimer.stop();
				this._transactionTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, verificationTimedOut);
				this._transactionTimer = null;
			}
		}
		
		private function verificationTimedOut(event : TimerEvent) : void
		{
			trace(this," :: transactionTimerComplete")
			stopVerificationTimer();
			manuallyFinishTransactions(_transactionCount);
			_transactionCount.length = 0;
			
			if( _onTransactionFailed )
			{
				_onTransactionFailed("", "Verification Timeout", "Transaction Verification timed out.\rTry again later.");
			}
		}
		
		private function verifyReceipt( storeKitEvent:StoreKitEvent ):void
		{	
			// keep track of product in case of time out, so it can be manually finsihed
			this._transactionCount.push(storeKitEvent.productId);
			
			trace(this,"purchaseTransactionSucceeded : verifying receipt at host: " + _host);
			
			// 
			if(StoreKit.storeKit.isAppReceiptAvailable())
			{
				// get a more up to date receipt
				StoreKit.storeKit.addEventListener(StoreKitEvent.APP_RECEIPT_REFRESHED, onReceiptRefreshed);
				StoreKit.storeKit.addEventListener(StoreKitErrorEvent.APP_RECEIPT_REFRESH_FAILED, onReceiptFailed);
				StoreKit.storeKit.refreshAppReceipt();
			}
			else
			{
				sendReceiptRequest(storeKitEvent);
			}
		}
		
		private function onReceiptFailed(event:StoreKitErrorEvent):void
		{
			StoreKit.storeKit.removeEventListener(StoreKitEvent.APP_RECEIPT_REFRESHED, onReceiptRefreshed);
			StoreKit.storeKit.removeEventListener(StoreKitErrorEvent.APP_RECEIPT_REFRESH_FAILED, onReceiptFailed);
			trace("failed to refresh receipt for: " + event.productId);
		}
		
		private function onReceiptRefreshed(storeKitEvent:StoreKitEvent):void
		{
			StoreKit.storeKit.removeEventListener(StoreKitEvent.APP_RECEIPT_REFRESHED, onReceiptRefreshed);
			StoreKit.storeKit.removeEventListener(StoreKitErrorEvent.APP_RECEIPT_REFRESH_FAILED, onReceiptFailed);
			sendReceiptRequest(storeKitEvent);
		}
		
		private function sendReceiptRequest(storeKitEvent:StoreKitEvent):void
		{
			var req:URLRequest = new URLRequest(_host + RECEIPT_VERIFICATION_CALL );
			req.method = URLRequestMethod.POST;
			var urlVars:URLVariables = new URLVariables();
			urlVars.receipt = storeKitEvent.receipt;//Base64.encode(storeKitEvent.receipt; // might be encoding whats already encoded
			trace("encoded receipt: " + urlVars.receipt);
			urlVars.id = _vendorID;
			urlVars['use'] = (AppConfig.production) ? "production" : "test";
			urlVars.login = _profile.login;
			
			req.data = urlVars;
			
			var ldr:URLLoader = new URLLoader(req);
			ldr.addEventListener( IOErrorEvent.IO_ERROR, Command.create(onVerificationError, storeKitEvent) );
			ldr.addEventListener( Event.COMPLETE, Command.create(onVerificationComplete, ldr, storeKitEvent) );
			ldr.load(req);
			
			startVerificationTimer();
		}
		
		/**
		 * Handler for failure to contact server for purchase verification.
		 * @param e
		 * @param storeKitEvent
		 */
		private function onVerificationError(e:IOErrorEvent, storeKitEvent:StoreKitEvent) : void
		{
			trace(this," :: onVerificationError : server can't be reached, error: " + e);
			
			stopVerificationTimer();
			removeTransactionID( storeKitEvent.productId );
			manuallyFinishTransactions([storeKitEvent.transactionId]);
			
			if(_onTransactionFailed)
			{
				_onTransactionFailed(storeKitEvent.productId, "Server Error", "Can't reach server, try again later.");
			}
		}
		
		/**
		 * 
		 * @param e
		 * @param ldr
		 * @param storeKitEvent
		 * List of response.statusCode:
		 21000 - The App Store could not read the JSON object you provided.
		 21002 - The data in the receipt-data property was malformed or missing.
		 21003 - The receipt could not be authenticated.
		 21004 - The shared secret you provided does not match the shared secret on file for your account. Only returned for iOS 6 style transaction receipts for auto-renewable subscriptions.
		 21005 - The receipt server is not currently available.
		 21006 - This receipt is valid but the subscription has expired. When this status code is returned to your server, the receipt data is also decoded and returned as part of the response. Only returned for iOS 6 style transaction receipts for auto-renewable subscriptions.
		 21007 - This receipt is from the test environment, but it was sent to the production environment for verification. Send it to the test environment instead.
		 21008 - This receipt is from the production environment, but it was sent to the test environment for verification. Send it to the production environment instead.
		 */
		private function onVerificationComplete(e:Event, ldr:URLLoader, storeKitEvent:StoreKitEvent) : void
		{
			stopVerificationTimer();
			removeTransactionID( storeKitEvent.productId );
			
			var response:Object = JSON.parse(ldr.data);
			trace(this," :: onVerificationComplete : receipt validation success, status code: " + response.statusCode + " response anser: " + response.answer )
			switch(response.answer)
			{
				case "ok" :
					trace(this,"purchaseTransactionSucceeded answer: ok, status code: " + response.statusCode);
					if(response.statusCode == 0)
					{
						manuallyFinishTransactions([storeKitEvent.transactionId]);
						_onTransactionFinished( storeKitEvent.productId );
					}
					else
					{
						manuallyFinishTransactions([storeKitEvent.transactionId]);
						_onTransactionFailed( storeKitEvent.productId, "Server Error", response.message );
					}
					break;
				
				case "missing" :
					trace(this,"purchaseTransactionSucceeded answer: missing");
					manuallyFinishTransactions([storeKitEvent.transactionId]);
					_onTransactionFailed( storeKitEvent.productId, "Server Error", response.message );
					break;
				
				case "invalid" :
					trace(this,"purchaseTransactionSucceeded answer: invalid")
					manuallyFinishTransactions([storeKitEvent.transactionId]);
					_onTransactionFailed( storeKitEvent.productId, "Server Error", response.message );
					break;
				
				default :
					trace(this,"purchaseTransactionSucceeded answer: " + response.answer + " is not a valid anser type. try again")
					//manuallyFinishTransactions([storeKitEvent.transactionId]);
					//_onTransactionFailed( storeKitEvent.productId, "Server Error", response.message );
					verifyReceipt(storeKitEvent);
					break;
			}
		}
		
		//////////////////////////////////// HELPERS 
		
		/**
		 * Manually finish all transactions, used if verifying transaction with own backend system.
		 * @param productIDArray
		 */
		private function manuallyFinishTransactions(productIDArray :Array) : void
		{
			if( _verifyReceipt )
			{
				if(productIDArray.length > 0)
				{	
					for(var i : int = 0 ; i < productIDArray.length ; i++)
					{
						StoreKit.storeKit.manualFinishTransaction(productIDArray[i]);
					}
				}
				else
				{
					trace(this," :: manuallyFinishTransactions : productIDArray is empty");
				}
			}
		}
		
		private function removeTransactionID(id : String) : void
		{
			if(_transactionCount.length > 0)
			{
				for(var i : int = 0 ; i < _transactionCount.length ; i++)
				{
					if(_transactionCount[i] == id)
					{
						_transactionCount.splice(i, 1);
					}
				}
			}
		}
		
		public function printTransaction(transaction:Object):void
		{
			trace(this,"printTransaction",transaction as StoreKitErrorEvent);
			trace("-------------------in Print Transaction----------------------");
			trace("identifier :"+transaction.productId);
			trace("productIdentifier: "+ transaction.validProducts[0].title);
			trace("receipt: "+transaction.receipt);
			trace("originalTransaction: "+transaction.originalTransactionId);
			trace("---------end of print transaction----------------------------");
		}		
		
		public function useLowerCase() : Boolean
		{
			return false;
		}
	}
}