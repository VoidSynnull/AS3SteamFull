package com.poptropica.platformSpecific.android
{
	import com.milkmangames.nativeextensions.android.AndroidIAB;
	import com.milkmangames.nativeextensions.android.AndroidItemDetails;
	import com.milkmangames.nativeextensions.android.AndroidPurchase;
	import com.milkmangames.nativeextensions.android.events.AndroidBillingErrorEvent;
	import com.milkmangames.nativeextensions.android.events.AndroidBillingEvent;
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
	
	
	public class AndroidProductStore implements IProductStore
	{
		private const RECEIPT_VERIFICATION_CALL:String = "/interface/call.php?class=PopAppPurchase&method=VerifyReceipt";
		private const TRANSACTION_TIMER_DELAY : int = 10000;
		
		//needs to take 2 params boolean for success and an array of successfully loaded products
		private var _restoreCallback : Function;
		private var _restoreLength : int = 0;
		//needs to take 2 params boolean for success and an array of successfully loaded products
		private var _productDetailsCallback : Function;
		private var _nonConsumableProductCallback : Function;
		private var _cancelCallback : Function;
		private var _failCallback : Function;
		private var _host:String
		private var _vendorID : String;
		private var _transactionTimer :Timer;
		
		private var _request : TransactionRequestData;
		
		private var _profile:ProfileData;
		
		public function AndroidProductStore()
		{
			if (!this.isSupported())
			{
				trace(this,"AndroidProductStore purchasing is not supported on this platform");
				return;
			}

			trace(this,"initializing AndroidProductStore");	
			
			AndroidIAB.create();
			
			trace(this,"AndroidProductStore Initialized");

			// listeners for billing service startup
			AndroidIAB.androidIAB.addEventListener(AndroidBillingEvent.SERVICE_READY,onServiceReady);
			AndroidIAB.androidIAB.addEventListener(AndroidBillingEvent.SERVICE_NOT_SUPPORTED, onServiceUnsupported);
			
			// listeners for making a purchase
			AndroidIAB.androidIAB.addEventListener(AndroidBillingEvent.PURCHASE_SUCCEEDED,purchaseTransactionSucceeded);
			AndroidIAB.androidIAB.addEventListener(AndroidBillingErrorEvent.PURCHASE_FAILED, purchaseTransactionFailed);
			
			// listeners for player's owned items
			AndroidIAB.androidIAB.addEventListener(AndroidBillingEvent.INVENTORY_LOADED, restoreTransactionSucceeded);
			AndroidIAB.androidIAB.addEventListener(AndroidBillingErrorEvent.LOAD_INVENTORY_FAILED, restoreTransactionFailed);
			
			// listeners for consuming an item
			//AndroidIAB.androidIAB.addEventListener(AndroidBillingEvent.CONSUME_SUCCEEDED, onConsumed);
			//AndroidIAB.androidIAB.addEventListener(AndroidBillingErrorEvent.CONSUME_FAILED, onConsumeFailed);
			
			// listeners for item details
			//AndroidIAB.androidIAB.addEventListener(AndroidBillingEvent.ITEM_DETAILS_LOADED, onItemDetails);
			//AndroidIAB.androidIAB.addEventListener(AndroidBillingErrorEvent.ITEM_DETAILS_FAILED, onDetailsFailed);
			
			
			AndroidIAB.androidIAB.startBillingService("MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAmPnvDZ+hwL3QQNx+7W50XkmWfTgVBULPB5O+7CQQtIFXoy0PpmiYL7m20fVCk3nxhZHSgtSHcOxQ/dX1zMbTQJtltKiPDP4RrpNnDEZzUb+37UB8YZxH6Il9xR6nkI9oetmcUBWtGod4URMTdgVDDgBJhGNsNinV/cK29DKGUMeXJetY0pCl5RL/T2ezDvB0Tq+O2SBKjMlp4OfVYoBIoY++h3J3VuyKeaAHlfNZ2k1T3Qrz2EN+vDGYABtPBCJGbM4jrx7VrVaPGYXI63YXIxDt21Z7x+p4EFAbkpVBiCL1Pp3yC0aoSjeIyRZOxVC52czKVNSKxoxPJ63V7+aPRQIDAQAB");
		}
		
		public function setProfile(profile:ProfileData):void
		{
			_profile = profile;
		}
		
		public function setUpHost(host:String):void
		{
			_host = host.replace("www","store");
		}
		
		public function requestTransaction( request:TransactionRequestData ):void
		{
			_request = request;
			
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
		
		/**
		 * Called once purchase has finished, this includes Apple purchase approval and receipt verification via our servers.
		 * This does not include purchase cancellation, which is user driven.
		 * @param productId
		 */
		private function onPurchaseFinished( productId:String ):void
		{
			trace(this," :: onPurchaseFinished : for product id: " + productId );
			
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
			
			_request.productId = productId;
			_request.errorType = type;
			_request.message = message;
			_request.failed();
		}
		
		private function onServiceReady(event:AndroidBillingEvent) : void
		{
			trace(this,"onServiceReady");
			if (!this.isAvailable())
			{
				//Should we alert user that they cannot make purchases?
				trace(this,"App Store purchasing is disabled on this device.");
				//return;
			}else{
				trace(this,"App store purchasing should work")
			}
		}
		
		private function onServiceUnsupported(event:AndroidBillingEvent) : void
		{
			trace(this,"onServiceUnsupported");
		}
		
		public function isSupported():Boolean
		{
			trace(this,"isSupported()",AndroidIAB.isSupported());
			return AndroidIAB.isSupported();
		}
		
		public function isAvailable():Boolean
		{
			trace(this,"isAvailable()",AndroidIAB.androidIAB.areSubscriptionsSupported());
			return AndroidIAB.androidIAB.areSubscriptionsSupported();
		}
		
		public function setManualMode(manaul:Boolean):void
		{
			//no specific need for android
		}
		
		private function getProductDetails() : void
		{
			trace(this,"getProductDetails()");
			AndroidIAB.androidIAB.loadItemDetails(_request.productIds);
		}
		
		public function productDetailsSucceeded(event:AndroidBillingEvent):void
		{
			trace(this,"productDetailsSucceeded()",event);
			
			_request.productDetails = new Array();
			// the itemDetails property now contains the item info
			for each(var item:AndroidItemDetails in event.itemDetails)
			{
				trace( productDetailsToString( item ) );
				_request.productDetails.push(item as Object);	
			}
			
			_request.completed();
		}
		
		private function productDetailsToString( item:AndroidItemDetails ):String
		{
			var string:String = "";
			string += "item id:"+item.itemId;
			string += "\rtitle:"+item.title;
			string += "\rdescription:"+item.description;
			string += "\rprice:"+item.price;
			return string
		}
		
		public function productDetailsFailed(event:AndroidBillingErrorEvent):void
		{
			trace(this,"productDetailsFailed()",event.errorID, event.text);
			
			_request.message = event.text+" "+event.errorID
			_request.errorType = "GoogleStoreFailure";
			_request.failed();
		}
		
		private function getConsumableProduct(id : String, callback : Function, cancelCallback:Function, failCallback:Function, host : String):void
		{
			trace(this,"getConsumableProduct()",id);
			
			//no Android implementation;
		}
		
		private function getNonConsumableProduct():void
		{
			trace(this,"getNonConsumableProduct()",_request.productId);
			
			_failCallback = onPurchaseFailed;
			_nonConsumableProductCallback = onPurchaseFinished;
			
			AndroidIAB.androidIAB.purchaseSubscriptionItem(_request.productId);
		}
		
		// NOT IN USE //
		/*
		private function transactionTimerComplete(event : TimerEvent) : void
		{
			this._transactionTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, transactionTimerComplete);
			trace("transactionTimerComplete")
			
			this._failCallback("", "TransactionTimeout", "Transaction Timed Out. Try Again Later");
		}
		*/
		
		/*
		private function purchaseTransactionCanceled(event:StoreKitEvent):void
		{
			trace(this,"purchaseTransactionCanceled",event);
			removeTransactionID(event.productId);
			if(transactionTimer){
			transactionTimer.stop();
			}
			if(cancelCallback){
			trace(this,"should cancel")
			this.cancelCallback(event.productId);
			}
			
			manuallyFinishTransactions([event.transactionId]);
		}
		*/
		
		private function purchaseTransactionSucceeded(event:AndroidBillingEvent):void
		{
			trace(event.purchaseToken + " " + event.jsonData);
			_request.productId = event.itemId;
			//_request.completed();
			sendReceiptRequest(event);
		}
		
		private function sendReceiptRequest(event:AndroidBillingEvent):void
		{
			var req:URLRequest = new URLRequest(_host + RECEIPT_VERIFICATION_CALL );
			req.method = URLRequestMethod.POST;
			var urlVars:URLVariables = new URLVariables();
			urlVars.receipt = event.jsonData;
			urlVars.id = _vendorID;
			urlVars['use'] = (AppConfig.production) ? "production" : "test";
			urlVars.login = _profile.login;
			
			req.data = urlVars;
			
			var ldr:URLLoader = new URLLoader(req);
			ldr.addEventListener( IOErrorEvent.IO_ERROR, Command.create(onVerificationError, event) );
			ldr.addEventListener( Event.COMPLETE, Command.create(onVerificationComplete, ldr, event) );
			ldr.load(req);
			
			startVerificationTimer();
		}
		
		private function onVerificationError(e:IOErrorEvent, storeKitEvent:AndroidBillingEvent) : void
		{
			trace(this," :: onVerificationError : server can't be reached, error: " + e);
			
			stopVerificationTimer();
			if(_failCallback)
			{
				_failCallback(storeKitEvent.itemId, "Server Error", "Can't reach server, try again later.");
			}
		}
		
		private function onVerificationComplete(e:Event, ldr:URLLoader, storeKitEvent:AndroidBillingEvent) : void
		{
			stopVerificationTimer();
			
			var response:Object = JSON.parse(ldr.data);
			trace(this," :: onVerificationComplete : receipt validation success, status code: " + response.statusCode + " response anser: " + response.answer )
			switch(response.answer)
			{
				case "ok" :
					trace(this,"purchaseTransactionSucceeded answer: ok, status code: " + response.statusCode);
					if(response.statusCode == 0)
					{
						_nonConsumableProductCallback( storeKitEvent.itemId );
					}
					else
					{
						_failCallback( storeKitEvent.itemId, "Server Error", response.message );
					}
					break;
				
				case "missing" :
					trace(this,"purchaseTransactionSucceeded answer: missing");
					_failCallback( storeKitEvent.itemId, "Server Error", response.message );
					break;
				
				case "invalid" :
					trace(this,"purchaseTransactionSucceeded answer: invalid")
					_failCallback( storeKitEvent.itemId, "Server Error", response.message );
					break;
				
				default :
					trace(this,"purchaseTransactionSucceeded answer: " + response.answer + " is not a valid anser type.")
					_failCallback( storeKitEvent.itemId, "Server Error", response.message );
					break;
			}
		}
		
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
			
			_failCallback("", "Verification Timeout", "Transaction Verification timed out.\rTry again later.");
		}

		private function purchaseTransactionFailed(event:AndroidBillingErrorEvent):void
		{
			_request.productId = event.itemId;

			if(event.errorID == 7)
			{
				trace(this,"User already purchased this item, changing this to a purchase success",event,event.itemId);
				_request.completed();
				return;
			}
			
			trace(this,"purchaseTransactionFailed",event,event.itemId);
			_request.errorType = "GoogleStoreFailure";
			_request.message = event.text+" "+event.errorID;
			trace(_request.message);
			_request.failed();
		}
		
		private function restoreTransactions() : void
		{
			trace(this,"restoreTransactions");
			AndroidIAB.androidIAB.loadPlayerInventory();
		}
		
		private function restoreTransactionSucceeded(event:AndroidBillingEvent):void
		{
			trace(this,"restoreTransactionSucceeded");
			for(var i : int = 0 ; i < event.purchases.length ; i++)
			{
				_request.productId = event.purchases[i].itemId;
				_request.completed();
			}
			
			_request.message = "Purchases have been restored.";
			_request.restoredAll();
		}
		
		private function restoreTransactionFailed(event:AndroidBillingErrorEvent):void
		{
			trace(this,"restoreTransactionFailed",event);
			
			_request.message = event.text+" "+event.errorID
			_request.errorType = "ProductStoreFailure";
			_request.productId = event.itemId;
			_request.failed();
		}

		public function printTransaction(transaction:Object):void
		{
			
		}
		
		public function useLowerCase() : Boolean
		{
			return true;
		}
	}
}