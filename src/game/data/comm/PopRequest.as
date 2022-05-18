package game.data.comm {
import com.novafusion.net.amfphp.Call;

/**
 * PopRequest encapsulates an AMFPHP service request
 * @author Rich Martin
 * 
 */
public class PopRequest {

	private var requestMethod:String;
	private var requestPayload:Object;
	private var requestResultHandler:Function;
	private var requestCall:Call;

	public function PopRequest(method:String=null, payload:Object=null, handler:Function=null, call:Call=null) {
		requestMethod = method;
		requestPayload = payload;
		requestResultHandler = handler;
		requestCall = call;
	}

	public function get method():String {	return requestMethod; }
	public function set method(newMethod:String):void {
		requestMethod = newMethod;
	}

	public function get payload():Object {	return requestPayload; }
	public function set payload(newPayload:Object):void {
		requestPayload = newPayload;
	}

	public function get handler():Function {	return requestResultHandler; }
	public function set handler(newResultHandler:Function):void {
		requestResultHandler = newResultHandler;
	}

	public function get call():Call {	return requestCall; }
	public function set call(newCall:Call):void {
		requestCall = newCall;
	}

	public function toString():String {
		return "[PopRequest method=" + method + ", payload=" + payload + " handler=" + handler + " call=" + call;
	}
}

}
