package com.poptropica.platformSpecific.android {

// import the symbols from the Amazon IAP API v1.0 ANE
import com.amazon.device.iap.cpt.AmazonIapV2;
import com.amazon.device.iap.cpt.AmazonIapV2Event;
import com.amazon.device.iap.cpt.GetProductDataResponse;
import com.amazon.device.iap.cpt.GetPurchaseUpdatesResponse;
import com.amazon.device.iap.cpt.GetUserDataResponse;
import com.amazon.device.iap.cpt.NotifyFulfillmentInput;
import com.amazon.device.iap.cpt.PurchaseReceipt;
import com.amazon.device.iap.cpt.PurchaseResponse;
import com.amazon.device.iap.cpt.ResetInput;
import com.amazon.device.iap.cpt.SkuInput;
import com.amazon.device.iap.cpt.SkusInput;
import com.poptropica.interfaces.IProductStore;

import flash.utils.Dictionary;

import game.data.dlc.TransactionRequestData;
import game.data.profile.ProfileData;

public class AmazonProductStore implements IProductStore {

	public static const TYPE_USER_DATA:String		= 'userData';

	private static const NOT_SUPPORTED:String		= 'NOT_SUPPORTED';
	private static const SUCCESSFUL:String			= 'SUCCESSFUL';
	private static const FAILED:String				= 'FAILED';
	private static const FULFILLED:String			= 'FULFILLED';
	private static const UNAVAILABLE:String			= 'UNAVAILABLE';
	private static const INVALID_SKU:String			= 'INVALID_SKU';
	private static const ALREADY_PURCHASED:String	= 'ALREADY_PURCHASED';

	private var pendingRequests:Dictionary = new Dictionary();		// keys are Amazon requestIDs, values are TransactionRequestDatas

	//// CONSTRUCTOR ////

	public function AmazonProductStore() {
		if (! AmazonIapV2.isSupported()) {
			trace("Amazon Purchase is not supported on this platform");
			return;
		}
		AmazonIapV2.addEventListener(AmazonIapV2Event.GET_USER_DATA_RESPONSE, onUserData);
		AmazonIapV2.addEventListener(AmazonIapV2Event.PURCHASE_RESPONSE, onPurchase);
		AmazonIapV2.addEventListener(AmazonIapV2Event.GET_PRODUCT_DATA_RESPONSE, onProductData);
		AmazonIapV2.addEventListener(AmazonIapV2Event.GET_PURCHASE_UPDATES_RESPONSE, onPurchaseUpdate);

		//runSomeTests();
		}

	//// ACCESSORS ////

	//// PUBLIC METHODS ////

	//// INTERNAL METHODS ////

	//// PROTECTED METHODS ////

	//// PRIVATE METHODS ////

	private function runSomeTests():void
	{
		var trd:TransactionRequestData = new TransactionRequestData();
		trd.type = TYPE_USER_DATA;
		requestTransaction(trd);

		trd = TransactionRequestData.requestRestoreAll();
		requestTransaction(trd);

		//trd = TransactionRequestData.requestDetails(new <String>['com.pearsoned.poptropica.bundles.galactichotdogs']);
		trd = TransactionRequestData.requestDetails(new <String>['TestSKUSeptFourTwentyFifteen']);
		requestTransaction(trd);

//		trd = TransactionRequestData.requestPurchase('Plankton-Roller');
//		requestTransaction(trd);
	}

	private function onUserData(e:AmazonIapV2Event):void
	{
trace("\nAmazonProductStore::onUserData()", e.toString());
trace(JSON.stringify(e.getUserDataResponse));

		var theResponse:GetUserDataResponse = e.getUserDataResponse;
		var theRequest:TransactionRequestData = releasePendingRequest(theResponse.requestId);
		if (!theRequest) {
			trace("AmazonProductStore::onUserData() could not find TransactionRequestData for key", theResponse.requestId);
			return;
		}
		switch (theResponse.status) {
			case SUCCESSFUL:
				theRequest.transactionData = {
					userId:			theResponse.amazonUserData.userId,
					marketplace:	theResponse.amazonUserData.marketplace
				};
				theRequest.completed();
				break;
			case FAILED:
				theRequest.message = 'failed to retrieve user data';
				theRequest.failed();
				break;
			case NOT_SUPPORTED:
			default:
				break;
		}
	}

	private function onPurchase(e:AmazonIapV2Event):void
	{
trace("\nAmazonProductStore::onPurchase()", e.toString());
trace(JSON.stringify(e.purchaseResponse));

		var theResponse:PurchaseResponse = e.purchaseResponse;

		// TODO: When we resume verifying receipts, we should not release the pending request until after the verification.
		// At that time, we need to switch to the code in line[this line plus three]
		// Failed purchases can release it here, since there will be no verification step
		var theRequest:TransactionRequestData = releasePendingRequest(theResponse.requestId);
//		var theRequest:TransactionRequestData = pendingRequests[theResponse.requestId];

		if (!theRequest) {
			trace("AmazonProductStore::onPurchase() could not find TransactionRequestData for key", theResponse.requestId);
			return;
		}
		switch (theResponse.status) {
			case ALREADY_PURCHASED:
				theRequest.completed();
				break;
			case SUCCESSFUL:
				theRequest.productId = theResponse.purchaseReceipt.sku;
				theRequest.transactionData = {
					userId:				theResponse.amazonUserData.userId,
					marketplace:		theResponse.amazonUserData.marketplace,
					receipt: {
						receiptId:		theResponse.purchaseReceipt.receiptId,
						cancelDate:		theResponse.purchaseReceipt.cancelDate,
						purchaseDate:	theResponse.purchaseReceipt.purchaseDate,
						sku:			theResponse.purchaseReceipt.sku,
						productType:	theResponse.purchaseReceipt.productType
					}
				};

				// TODO: insert this validation procedure into the sequence
				// verifyReceipt(theResponse.amazonUserData.userId, theResponse.purchaseReceipt.receiptId, theResponse.requestId);
				// TODO: when the above call is activated, the next two statements will be deferred until the verification is performed

				// is this what I'm supposed to do here? still kinda fuzzy about this NotifyFulfillment bidniz
				AmazonIapV2.notifyFulfillment(new NotifyFulfillmentInput(theResponse.purchaseReceipt.receiptId, FULFILLED));	// I don't think we care about the return value here. Won't it be the same receiptId that we passed in?

				theRequest.completed();
				break;
			case NOT_SUPPORTED:
				theRequest.message = "purchase not supported";
				theRequest.failed();
				break;
			case FAILED:
				//Drew - Testing IAP. Seems like canceled purchases were not accounted for.
				//If cancelData != 0, then that means the purchase was canceled, according to the (horrible) documentation. I think?
				if(e.purchaseResponse.purchaseReceipt != null && e.purchaseResponse.purchaseReceipt.cancelDate != 0)
				{
					theRequest.cancelled();
				}
				else
				{
					theRequest.failed();
				}
				break;
			case INVALID_SKU:
				theRequest.message = "invalid:" + theResponse.purchaseReceipt.sku;
				theRequest.failed();
				break;
				break;
			default:
				break;
		}
		// Until we resume verifying receipts, it is harmless to delete non-existent keys. After that, it is necessary.
		if (SUCCESSFUL != theResponse.status) {
			delete pendingRequests[theResponse.requestId];
		}
	}

	private function verifyReceipt(userID:String, receiptID:String, requestID:String):void
	{
		// Send the three arguments to Dan, along with the requestId and a 'production' flag.
		// Depending on the nature of the app, he will request validation from either his local RVS Sandbox (dev/qa builds)
		// or Amazon's official Receipt Verification Service (production builds). The only distinction is in the request URL.
//		askDanForVerification(userID, receiptID, requestID, AppConfig.production);
		// We'll have to provide a callback for his asynchronous response.
	}

	private function onReceiptVerification(someResponseContainer:Object):void
	{
		var requestId:String = someResponseContainer.requestId;
		var theRequest:TransactionRequestData = releasePendingRequest(requestId);
		var receiptId:String = someResponseContainer.receiptId;	// this arg is totally fake, just to keep the compiler happy until Dan joins the fun
		if (someResponseContainer.succeeded) {
			// Finally, we can call notifyFulfillment() and dispatch completed
			AmazonIapV2.notifyFulfillment(new NotifyFulfillmentInput(receiptId, FULFILLED));	// I don't think we care about the return value here. Won't it be the same receiptId that we passed in?
			theRequest.completed();
		} else {
			theRequest.message = "receipt verification failed";
			theRequest.failed();
		}
	}

	private function onProductData(e:AmazonIapV2Event):void
	{
trace("\nAmazonProductStore::onProductData()", e.toString());
trace(JSON.stringify(e.getProductDataResponse));

		var theResponse:GetProductDataResponse = e.getProductDataResponse;
		var theRequest:TransactionRequestData = releasePendingRequest(theResponse.requestId);
		if (!theRequest) {
			trace("AmazonProductStore::onProductData() could not find TransactionRequestData for key", theResponse.requestId);
			return;
		}
		switch (theResponse.status) {
			case SUCCESSFUL:
				theRequest.productDetails = [];
				for (var sku:String in theResponse.productDataMap) {
					var product:Object = theResponse.productDataMap[sku];
					theRequest.productDetails.push(
						{
							icon:			product.smallIconUrl,
							itemId:			product.sku,
							itemType:		product.productType,
							price:			product.price,
							title:			product.title,
							description:	product.description
						}
					);
				}
				theRequest.transactionData = {
					unavailableSkus:	theResponse.unavailableSkus
				};
				theRequest.completed();
				break;
			case NOT_SUPPORTED:
				theRequest.message = "product data not supported";
				theRequest.failed();
				break;
			case FAILED:
				theRequest.failed();
				break;
			default:
				break;
		}
	}

	private function onPurchaseUpdate(e:AmazonIapV2Event):void
	{
trace("\nAmazonProductStore::onPurchaseUpdate()", e.toString());
trace(JSON.stringify(e.getPurchaseUpdatesResponse));

		var theResponse:GetPurchaseUpdatesResponse = e.getPurchaseUpdatesResponse;
		var theRequest:TransactionRequestData = releasePendingRequest(theResponse.requestId);
		if (!theRequest) {
			trace("AmazonProductStore::onPurchaseUpdate() could not find TransactionRequestData for key", theResponse.requestId);
			return;
		}
		switch (theResponse.status) {
			case SUCCESSFUL:
				var numReceipts:uint = theResponse.receipts.length;
				for (var i:int=0; i<numReceipts; i++) {
					var theReceipt:PurchaseReceipt = theResponse.receipts[i];
trace("receipt SKU:",theReceipt.sku); 
					theRequest.productId = theReceipt.sku;
					theRequest.transactionData = {
						receiptId:		theReceipt.receiptId,
						cancelDate:		theReceipt.cancelDate,
						purchaseDate:	theReceipt.purchaseDate,
						productType:	theReceipt.productType
					};
trace("calling completed callback", theRequest.completed, "for", theRequest);
					theRequest.completed();
				}
				theRequest.message = "Purchases have been restored";
				theRequest.restoredAll();
				break;
			case NOT_SUPPORTED:
				theRequest.message = "purchase receipts not supported";
				theRequest.failed();
				break;
			case FAILED:
				theRequest.failed();
				break;
			default:
				break;
		}
	}

	/**
	 * Removes the TransactionRequestData whose key is <code>theID</code>
	 * from the cache and returns it to the client.
	 * @param theID	A UUID generated by Amazon App Store and used as a <code>Dictionary</code> key for the request
	 * @return The request, or <code>null</code> if no such key found
	 * 
	 */	
	private function releasePendingRequest(theID:String):TransactionRequestData
	{
trace("\nAmazonProductStore::releasePendingRequest() gets id", theID, "will delete", pendingRequests[theID]);
		var theRequest:TransactionRequestData = pendingRequests[theID];
		delete pendingRequests[theID];
		return theRequest;
	}

	//// INTERFACE IMPLEMENTATIONS ////

	//// IProductStore implementation

	/**
	 * Indicates whether app is running on an Android device
	 */
	public function isSupported():Boolean
	{
		return AmazonIapV2.isSupported();
	}

	/**
	 * Indicates whether purchases are allowed on this device
	 */
	public function isAvailable():Boolean
	{
		// does the SDK provide an answer for this?
		// how do we know if purchasing is forbidden?
			// Note: in AndroidProductStore, this call provides the answer to
			// the question: Are subscriptions supported?
			// in IosProductStore, this call provides the answer to
			// the question: Is the StoreKit available?
		return true;	// lacking reliable data, assume we can purchase
	}
	
	public function setManualMode(manaul:Boolean):void
	{
		//no specific need for android
	}
	
	public function setUpHost(host:String):void
	{
		//_host = host.replace("www","store"); not a thing yet
	}
	
	public function setProfile(profile:ProfileData):void
	{
		//_profile = profile;
	}
	
	public function requestTransaction(request:TransactionRequestData):void
	{
		var pendingID:String;

		switch (request.type) {
			case TYPE_USER_DATA:
				pendingID = AmazonIapV2.getUserData().requestId;
trace("A call to getUserData() returns a requestID:", pendingID);
				break;

			case TransactionRequestData.TYPE_DETAILS:
				pendingID = AmazonIapV2.getProductData(new SkusInput(request.productIds)).requestId;
trace("Call 2 getProductData() returns a requestID:", pendingID);
				break;

			case TransactionRequestData.TYPE_PURCHASE:
				pendingID = AmazonIapV2.purchase(new SkuInput(request.productId)).requestId;
trace("That call to purchase() returns a requestID:", pendingID);
				break;

			case TransactionRequestData.TYPE_RESTORE:
				// ResetInput(<boolean>) false (default) = get purchases since last call, true = get ALL purchases
				pendingID = AmazonIapV2.getPurchaseUpdates(new ResetInput(true)).requestId;
trace("To getPurchaseUpdates() returns a requestID:", pendingID);
				break;

			default:
				break;
		}
		if (pendingID) {
			pendingRequests[pendingID] = request;
		}
	}

	public function printTransaction(transaction:Object):void
	{
		trace("No printing of transactions");
	}
	
	public function useLowerCase():Boolean
	{
		return true;
	}
}

}
