package game.scenes.virusHunter.pdcLab
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
	
	public class VirusPopupVideo extends Popup
	{
		public function VirusPopupVideo(container:DisplayObjectContainer=null)
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
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();
			
			super.darkenBackground = true;
			super.groupPrefix = "scenes/virusHunter/pdcLab/";
			super.screenAsset = "virusPopupVideo.swf";
			super.init(container);
			super.load();
		}		
		
		// all assets ready
		override public function loaded():void
		{
			super.preparePopup();
			
			// this centers the movieclip 'content' within examplePopup.swf.  For wide layouts this will center horizontally, for tall layouts vertically.
			//trace("super.screen:"+super.screen);
			super.layout.centerUI(super.screen.content);
			
			//That didn't work. Let's try copying the nextconnection and stream stuff over directly
			_connection = new NetConnection();
			_connection.addEventListener(NetStatusEvent.NET_STATUS, fnStatus);
			//_connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fnSecurityError);
			_connection.connect(null);
			
			super.groupReady();
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
					trace("Ad Video Player: Unable to locate video");
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
			
			// set buffer to 0.1 seconds
			_stream.bufferTime = 0.1;
			
			// metadata
			var vMetaData:Object=new Object();
			_stream.client = vMetaData;
			
			// setup video and stream
			_videoPlayer = new Video(450, 318);
			super.screen.content.videoClip.addChild(_videoPlayer);
			_videoPlayer.attachNetStream(_stream);
			
			// determine location of video
			_videoFile = super.shellApi.assetPrefix + "scenes/virusHunter/pdcLab/virusPSA_small.flv";
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