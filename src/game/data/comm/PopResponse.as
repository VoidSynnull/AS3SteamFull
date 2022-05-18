package game.data.comm {

public class PopResponse {

	import flash.net.URLVariables;
	import game.proxy.GatewayConstants;
	import game.util.DataUtils;

	private static const NEWBORN_STATUS:int	= 0;

	private var responseStatus:int;
	private var responseData:URLVariables;
	private var responseError:Object;

	//// CONSTRUCTOR ////

	/**
	 * PopResponse is a value object which formalizes the structure of a
	 * message from the game’s network environment. When instantiated with no arguments,
	 * it is a “newborn” response without data of any kind.
	 * Newborn PopResponses are not considered valid. Client code is encouraged to inspect
	 * the <code>isValid</code> property before attempting to act upon a PopResponse’s data.
	 * <p>Note that is quite possible to instantiate a <code>PopResponse</code> with useful data,
	 * but whose <code>status</code> is zero. Under normal
	 * circumstances, such an object would be ignored.</p>
	 * 
	 * @param initStatus	An <code>int</code> taken from the “PopError/PopSuccess codes” section of <code>GatewayConstants</code>.
	 * @param initData	A URLVariables object containing URLEncoded key-value pairs
	 * @param initError	An <code>Object</code> (usually a <code>String</code>) containing data about the error
	 * @see game.proxy.GatewayConstants
	 */
	// TODO: consider formalizing a PopError
	public function PopResponse(initStatus:int=NEWBORN_STATUS, initData:URLVariables=null, initError:Object=null) {
		responseStatus = initStatus;
		responseData = initData;
		responseError = initError;
	}

	//// ACCESSORS ////

	public function get isValid():Boolean {	return NEWBORN_STATUS != status; }

	public function get succeeded():Boolean { return GatewayConstants.AMFPHP_SUCCESS == status; }

	/**
	 * The status membar of a <code>PopResponse</code> can be said to be in one of three states.
	 * A <code>PopResponse</code> whose status is <code>PopResponse.NEWBORN_STATUS</code>
	 * indicates the object is content-free and not to be acted upon. A <code>PopResponse</code>
	 * whose status is <code>GatewayConstants.AMFPHP_UNDEFINED</code> indicates the object
	 * contains data, but its status is unknown. Otherwise, a <code>PopResponse’s</code>
	 * status ought to be one of the remaining values in the “PopError/PopSuccess codes” section of <code>GatewayConstants</code>.
	 * @return 
	 */	
	public function get status():int {	return responseStatus; }
	/**
	 * @private
	 */	
	public function set status(newStatus:int):void {
		responseStatus = newStatus;
	}

	/**
	 * The data member of a <code>PopResponse</code> is a <code>URLVariables</code> object
	 * containing a set of URLEncoded name-value pairs.
	 * @return 
	 */	
	public function get data():URLVariables {	return responseData; }
	/**
	 * @private
	 */	
	public function set data(newData:URLVariables):void {
		responseData = newData;
		if (NEWBORN_STATUS == status) {
			status = GatewayConstants.AMFPHP_UNDEFINED;
		}
	}

	/**
	 * The error member of a <code>PopResponse</code> contains information about
	 * an error which has occured when attempting a network connection. In its
	 * simplest format, it is a <code>String</code> which describes the nature
	 * of the error. Presently considering the definition of a PopError class which could
	 * provide deluxe error info.
	 * @return 
	 */	
	public function get error():Object {	return responseError; }
	/**
	 * @private
	 */	
	public function set error(newError:Object):void {
		responseError = newError;
		if (NEWBORN_STATUS == status) {
			status = GatewayConstants.AMFPHP_UNDEFINED;
		}
	}

	//// PUBLIC METHODS ////

	public function updateFromObject(o:Object):void {
		for (var prop:String in o) {
			//trace("PopResponse::updateFromObject():", prop, "itz", o[prop]);
			switch (prop) {
				case 'status':
					status = DataUtils.useNumber(o.status, GatewayConstants.AMFPHP_PROBLEM);
					break;
				case 'error':
					error = o.error;
					break;
				default:
					if (!data) {
						data = new URLVariables();
					}
					//trace('copying', p, o[p], 'to response');
					data[prop] = o[prop];
					break
			}
		}
	}

	public function toString():String {
		var summary:String = '[PopResponse status: ';
		if (NEWBORN_STATUS == responseStatus) {
			summary += 'uninitialized';
		} else {	// convert server's statuscode number to a human-readable value
			summary += GatewayConstants.resultNameForCode(status) + ',';
		}

		if (responseError) {
			summary += ' error: ' + JSON.stringify(responseError);
		}

		if (responseData) {
			summary += ' data: ' + unescape(responseData.toString());
		}
		summary += ']';

		return summary;
	}

}

}
