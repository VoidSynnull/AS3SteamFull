package game.proxy {
import flash.events.NetStatusEvent;
import flash.external.ExternalInterface;

// TODO: more statefulness. right now, overlapping transactions cause Signal mixups
// we need discrete transactions, each with its separate Signals

/**
 * Remoting is the base class for Remote server calls using AMFPHP.
 * Clients wishing to exchange data via AMFPHP need to go like-a this-a:
 * 
 * <p><code>var remoteService:Remoting = new Remoting("http://server.example.com/amfphpgateway/gateway.php");</code><br />
 * <code>remoteService.remoteError.add(errorHandler);</code><br />
 * <code>remoteService.remoteResult.add(resultHandler);</code></p>
 * 
 * <p>Each handler takes the form:
 * <code>function (o:Object):void {}</code>. Consult your gateway's author to
 * discover the useful properties of the result object.</p>
 * 
 * <p>To communicate with the AMFPHP gateway:</p>
 * 
 * <p><code>remoteService.call("serviceName", "methodName", {name:value});</code></p>
 * 
 * <p>When a response arrives from the gateway, a <code>Signal</code> will be
 * dispatched. If an error has occured, a <code>remoteError</code> signal will
 * carry the gateway's error <code>Object</code>. Successful receipt of a
 * gateway response results in a <code>remoteResult</code> signal, which carries
 * the gateway's result <code>Object</code>.</p>
 * 
 * @see http://www.silexlabs.org/amfphp/
 *  
 * @author Rich Martin
 */
public class Remoting {

	import flash.net.NetConnection;
	import flash.net.ObjectEncoding;
	import flash.net.Responder;
	import org.osflash.signals.Signal;
	
	public static const STATUS_IDLE:uint		= 0;
	public static const STATUS_WAITING:uint		= 1;

	public var remoteError:Signal;
	public var remoteResult:Signal;

	protected var service:NetConnection;
	protected var gatewayResponder:Responder;
	protected var status:uint = STATUS_IDLE;
	protected var previousCall:Array;

	//// CONSTRUCTOR ////

	public function Remoting(gatewayURL:String='') {
		try {
			service = new NetConnection();
		} catch (e:Error) {
			logWWW("error opening new netconnection has been ignored");
		}

		service.addEventListener(NetStatusEvent.NET_STATUS, onServiceStatus);
		initService(gatewayURL);
		gatewayResponder = new Responder(onServiceResult, onServiceError);
		remoteError = new Signal(Object);
		remoteResult = new Signal(Object);
	}

	//// ACCESSORS ////

	public function get gateway():String {	return service.uri; }
	public function set gateway(newGatewayURL:String):void {
		if (newGatewayURL) {
			service.connect(newGatewayURL);
		}
	}

	public function get responder():Responder {	return gatewayResponder; }
	public function set responder(newResponder:Responder):void {
		gatewayResponder = newResponder;
	}

	//// PUBLIC METHODS ////

	public function destroy():void {
		remoteError.removeAll();
		remoteResult.removeAll();
		status = STATUS_IDLE
	}

	public function call(serviceName:String, methodName:String, ...args):void {
		if (!(serviceName || methodName)) {
			return;
		}

		var allArgs:Array = [];
		allArgs.push(serviceName + '/' + methodName);
		allArgs.push(gatewayResponder);
		for (var i:int=0; i<args.length; i++) {
			allArgs.push(args[i]);
		}

		if (STATUS_WAITING == status) {
			logWWW("issuing a call in the middle of a wait!");
			if (previousCall.length) {
				logWWW("previous call was", previousCall);
			} else logWWW("how odd - gateway status is waiting and yet there is no previous call");
			logWWW("interrupting call is", allArgs);
		}
		previousCall = allArgs.concat();	// get a copy, not a reference

		var serviceFunction:Function = service.call;
		serviceFunction.apply(service, allArgs);
		status = STATUS_WAITING;
	}

	//// INTERNAL METHODS ////

	//// PROTECTED METHODS ////

	protected function onServiceStatus(e:NetStatusEvent):void {
		for (var p:String in e.info) logWWW(p, '=', e.info[p]);
		remoteError.dispatch(e.info);
	//	status = STATUS_IDLE
	}

	protected function onServiceError(errorData:Object):void {
		remoteError.dispatch(errorData);
		status = STATUS_IDLE
	}

	protected function onServiceResult(resultData:Object):void {
		remoteResult.dispatch(resultData);
		status = STATUS_IDLE
	}
	
	protected function logWWW(...msgs):void {		// for debugging only
		var dbugStr:String = "Remoting: " + msgs.join(' ');
		if (ExternalInterface.available) {
			ExternalInterface.call('dbug', dbugStr);
		}
		trace(dbugStr);
	}

	//// PRIVATE METHODS ////

	private function initService(gatewayURL:String):void {
		service.objectEncoding = ObjectEncoding.AMF3;
		gateway = gatewayURL;
	}

}

}
