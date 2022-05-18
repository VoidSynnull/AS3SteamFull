package game.proxy {
import flash.net.URLRequestMethod;
import flash.net.URLVariables;
import flash.utils.getTimer;

public class FENErrorLogger {

	private var connection:Connection;
	private var payload:URLVariables;
	private var _lastErrorTime:int;
	private var MIN_ERROR_WAIT:int = 5000;
	private var _lastStacktrace:String;

	//// CONSTRUCTOR ////

	public function FENErrorLogger()
	{
	}

	//// ACCESSORS ////

	//// PUBLIC METHODS ////

	public function log(stackTrace:String):void
	{
		var errorTimeDelta:Number =  getTimer() - _lastErrorTime;
		
		if (errorTimeDelta > MIN_ERROR_WAIT && stackTrace != _lastStacktrace && connection) {
			_lastErrorTime = getTimer();
			_lastStacktrace = stackTrace;
			payload.stack = stackTrace;
			connection.connect('/crash-record.php', payload, URLRequestMethod.POST, onReply, onReply);
		}
	}

	// CreateTracker shellstep will invoke this with app-specific values
	public function init(host:String, login:String, platform:String, version:String):void
	{
		connection = new Connection();
		connection.prefix = host;

		payload = new URLVariables();
		payload.login		= login;
		payload.platform	= platform;
		payload.version		= version;
		payload.stack		= null;
	}

	//// INTERNAL METHODS ////

	//// PROTECTED METHODS ////

	//// PRIVATE METHODS ////

	private function onReply(e:*):void
	{
		trace("FENErrorLogger::onReply()", e);
	}

	//// INTERFACE IMPLEMENTATIONS ////

}

}
