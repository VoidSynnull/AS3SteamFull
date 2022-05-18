package game.scenes.lands.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.NetStatusEvent;
	import flash.geom.Point;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	import game.data.ui.TransitionData;
	import game.ui.popup.Popup;
	
	import org.osflash.signals.Signal;
	
	public class RealmsPopupVideo extends Popup
	{
		public function RealmsPopupVideo(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			// call the super class's 'destroy()' method as well to finish cleanup of this group which removes any entites and systems specific to this group, as well as removing the groupContainer.
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			
			// setup the transitions
			/*
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();
			*/
			//super.darkenAlpha = 1;
			//super.darkenBackground = true;
			
			super.groupPrefix = "scenes/lands/shared/popups/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["realmsPopupVideo.swf"]);
		}
		
		// all assets ready
		override public function loaded():void
		{
			
			super.screen = super.getAsset("realmsPopupVideo.swf", true) as MovieClip;
			// this loads the standard close button
			//super.loadCloseButton();
			
			// this centers the movieclip 'content' within examplePopup.swf.  For wide layouts this will center horizontally, for tall layouts vertically.
			super.layout.centerUI(super.screen.content);
		
			_connection = new NetConnection();
			_connection.addEventListener(NetStatusEvent.NET_STATUS, fnStatus);
			//_connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fnSecurityError);
			_connection.connect(null);
			
			super.loaded();
		}
		
		private function fnStatus(aEvent:NetStatusEvent):void
		{
			switch (aEvent.info.code) {
				case "NetConnection.Connect.Success":
					// successful connection, now connect stream
					fnConnectStream();
					break;
				case "NetStream.Play.StreamNotFound":
					// video not found
					trace("Video Player: Unable to locate video");
					break;
				case "NetStream.Play.Stop":
					// video reaches end
					endVideo();
					break;
			}
		}
		
		private function fnConnectStream():void
		{
			// set up stream
			_stream = new NetStream(_connection);
			_stream.addEventListener(NetStatusEvent.NET_STATUS, fnStatus);
			//_stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, fnAsyncError);
			
			// set buffer to 0.4 seconds
			_stream.bufferTime = 3;
			
			// metadata
			var vMetaData:Object=new Object();
			//vMetaData.onMetaData = fnMetaData;
			_stream.client = vMetaData;
			
			// setup video and stream
			_videoPlayer = new Video(960, 640);
			super.screen.content.videoClip.addChild(_videoPlayer);
			//for testing black background - remove eventually
			//super.screen.content.videoClip.x += 200;
			_videoPlayer.attachNetStream(_stream);
			
			// determine location of video
			_videoFile = super.shellApi.assetPrefix + "scenes/lands/shared/popups/realms_intro.flv";
			//var vVideoPath:String;
			// if air runtime (not in web page)
			//if (Capabilities.playerType == "Desktop")
				//vVideoPath = _videoFile;
			//else
				//vVideoPath = _videoFile;
			_stream.play(_videoFile);
		}
		
		public function endVideo():void
		{
			super.close();
		}
		
		public var finishedVideo:Signal;
		private var _connection:NetConnection;
		private var _stream:NetStream;
		private var _videoPlayer:Video;
		private var _videoFile:String;
	}
}