package game.scenes.hub.theater
{
	import flash.display.Stage;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.LocationChangeEvent;
	import flash.geom.Rectangle;
	import flash.media.StageWebView;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import engine.ShellApi;
	
	public class MobileVideos
	{
		private var webView:StageWebView;
		private var closeFunct:Function;
		private var shellApi:ShellApi;
		
		public function MobileVideos(shellApi:ShellApi, closeTheaterVideo:Function)
		{
			closeFunct = closeTheaterVideo;
			this.shellApi = shellApi;
			var stage:Stage = (shellApi.screenManager).sceneContainer.stage;
			trace("StageWebView supported " + StageWebView.isSupported);
			
			if (StageWebView.isSupported)
			{				
				webView = new StageWebView();
				webView.stage = (shellApi.screenManager).sceneContainer.stage;
				webView.viewPort = new Rectangle( 0, 0, stage.stageWidth, stage.stageHeight);
				
				webView.addEventListener( Event.COMPLETE, doneLoading );
				webView.addEventListener( ErrorEvent.ERROR, errorTrace );
				webView.addEventListener( LocationChangeEvent.LOCATION_CHANGING, changing );
				
				// use batterypop.html so this works on legacy devices
				webView.loadURL( "https://www.poptropica.com/batterypop.html" );
			}
		}
		
		// listen for when page changes
		private function changing(event:LocationChangeEvent):void
		{
			trace("location: " + event.location);
			// if Poptropica URL
			if (event.location.indexOf("https://www.poptropica.com") == 0)
			{
				// when clicking close button
				if ((event.location == "https://www.poptropica.com") || (event.location == "https://www.poptropica.com/"))
				{
					closeFunct();				
					webView.stage = null;
					webView.dispose();
				}
			}
			// if not playwire URL
			else if (event.location.indexOf("playwire.com") == -1)
			{
				trace("_____Playwire location changing to " +event.location);
				
				// if force browser is present
				if (event.location.indexOf("forcebrowser=true") != -1)
				{
					// load sponsor site in mobile browser
					navigateToURL(new URLRequest(event.location), "_blank");
					// halt the current load operation
					webView.stop();
				}
			}
		}
		
		private function doneLoading(event:Event):void
		{
			trace("Loading complete");
		}
		
		private function errorTrace(event:ErrorEvent):void
		{
			trace("Loading error: " +  event.text);
		}
	}
}