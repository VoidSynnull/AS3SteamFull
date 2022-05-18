package game.proxy
{	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import game.util.PlatformUtils;
	
	import org.osflash.signals.natives.NativeSignal;

	public class Connection
	{		
		public function Connection()
		{
			_loader = new URLLoader();
			loaded = new NativeSignal(_loader, Event.COMPLETE, Event);
			loaded.add(handleLoaded);
			error = new NativeSignal(_loader, IOErrorEvent.IO_ERROR, IOErrorEvent);
			error.add(handleError);
			secure = new NativeSignal(_loader, SecurityErrorEvent.SECURITY_ERROR, SecurityErrorEvent);
			secure.add(handleSecurityError);
		}

		public function destroy():void
		{
			_loader = null;
			loaded.removeAll();
			error.removeAll();
		}
		
		public function connect(url:String, vars:URLVariables = null, requestMethod:String = URLRequestMethod.POST, loadedCallback:Function = null, errorCallback:Function = null):void
		{
			var reqURL:String = url;
			if (PlatformUtils.isMobileOS) {	// Only use a fully qualified URL when on mobile. Browser gameplay will use a root-relative URL.
				reqURL = prefix + url;
			}
			if (reqURL.indexOf("brain/track.php") != -1) {
				reqURL = "https://www.poptropica.com/brain/track.php";
			}
			var request:URLRequest = new URLRequest(reqURL);
			request.method = requestMethod;
			
			if(vars != null)
			{
				request.data = vars;
			}
			
			loadRequest(request, loadedCallback, errorCallback);
		}

		public function loadRequest(req:URLRequest, loadedCallback:Function = null, errorCallback:Function = null):void
		{
			if (loadedCallback) {
				loaded.addOnce(loadedCallback);
			}
			if (errorCallback) {
				error.addOnce(errorCallback);
			}
			_loader.load(req);
		}

		private function dbug(...msgs):void {
			var dbugStr:String = msgs.join(' ');
			if (ExternalInterface.available) {
				ExternalInterface.call('dbug', dbugStr);
			}
			trace(dbugStr);
		}

		private function handleError(event:IOErrorEvent):void
		{
			dbug("Connection :: Unable to connect to network.", event.text);
		}
		
		private function handleLoaded(event:Event):void
		{
			
		}

		private function handleSecurityError(e:SecurityErrorEvent):void {
			dbug("security:", e.text);
		}

		private var _loader:URLLoader;
		public var loaded:NativeSignal;
		public var error:NativeSignal;
		public var secure:NativeSignal;
		public var prefix:String = "";
	}
}