package game.components.video
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.AsyncErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.URLLoader;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.group.Group;
	import engine.systems.AudioSystem;
	
	
	public class PopVideo extends Component
	{
		// status string can be: "start", "playing", "done", "paused", "end", "replay"
		public var pStatus:String = "";
		//reference to group so that we can call shellApi functions
		private var _group:Group;
		// video container movieclip and timeline
		private var _container:MovieClip;
		//private var _fsVideo:AdFullScreenVideo;
		// streaming variables
		private var _connection:NetConnection;
		private var _stream:NetStream;
		private var _videoPlayer:Video;
		private var _videoClip:DisplayObject;
		private var _videoUI:MovieClip;
		// video variables
		private var _videoWidth:int = 300;
		private var _videoHeight:int = 170;
		private var _videoFile:String; // path to video file string
		private var _videoFiles:Array; // array video files
		private var _videoDuration:int; // length of video, currently only used by VAST tracking
		private var _videoNumber:int;
		
		private var _audioSystem:AudioSystem;
		
		// vast variables
		
		// set when VAST is detected in the file2 parameter (represented by starting with "VAST=")
		private var _vastEnabled:Boolean;
		// set when VAST tag has been loaded and parsed; prevents video from being set up until media location is pulled from VAST tag
		private var _vastReady:Boolean;
		// set when VAST-enabled video is being replayed; forces re-load and re-parse of VAST tag
		private var _vastReset:Boolean;
		// set when VAST-enabled video has already been viewed (used to fire the correct tracking event on replay)
		private var _vastReplay:Boolean;
		// VAST tag URL
		private var _vastTagURL:String;
		// used to keep track of progress during video for progress reporting events
		private var _vastNextProgressEvent:int;
		// set when video should immediately pay after VAST load
		private var _vastAutoPlay:Boolean;
		// entity that will be clicked once autoplay occurs
		private var _vastAutoPlayClickEntity:Entity;
		
		
		// current VAST XML data
		private var _vastXML:XML;
		// VAST XML loader
		private var _vastXMLLoader:URLLoader;
		
		// tracking links
		private var _vastVideoImpressionURLs:Array;
		private var _vastTrackVideoStartURLs:Array;
		private var _vastTrackVideoFirstQuartileURLs:Array;
		private var _vastTrackVideoMidpointURLs:Array;
		private var _vastTrackVideoThirdQuartileURLs:Array;
		private var _vastTrackVideoCompleteURLs:Array;
		private var _vastVideoClickTrackingURLs:Array;
		
		// click-through URL
		private var _vastVideoClickThroughURL:String;
		
		private const CARD_PREFIX:String = "hasAdItem_";
		private var _card:String;
		
		/**
		 * Contstructor
		 * @param	entity	 		video timeline entity
		 * @param	container		video container
		 * @param	videoData		Object that contains all video data
		 * @param	scene
		 */
		public function PopVideo(entity:Entity, container:MovieClip, videoData:Object, group:Group):void
		{
			// video container and timeline and scene
			_container = container;
			_group = group;
			
			// get variables
			if (videoData.width != null)
				_videoWidth = int(videoData.width);
			if (videoData.height != null)
				_videoHeight = int(videoData.height);
			if (videoData.videoFile != null)
			{
				// do not use VAST
				if ( videoData.videoFile.indexOf("VAST=") == -1 )
				{
					_vastEnabled = false;
					_videoFiles = videoData.videoFile.split(",");
				}
				else
				{
					// enable VAST
					// set up VAST-related variables
					_vastEnabled = true;
					_vastReady = false;
					_vastReset = false;
					_vastReplay = false;
					_vastAutoPlay = false;
					
					// parse out VAST tag location
					_vastTagURL = videoData.videoFile.substr(5);				
				}
			}
		}
				
		/**
		 * Play Video (called from system in response to "start")
		 */
		public function fnPlay():void
		{
			// if no video then fade to end screen
			if (_videoFiles == null)
			{
				pStatus = "done";
			}
			else
			{
				pStatus = "playing";
				
				// if full screen, then play fullscreen
				//if (_fsVideo)
					//_fsVideo.play();
				//else
				{
					// setup connection
					_connection = new NetConnection();
					_connection.addEventListener(NetStatusEvent.NET_STATUS, fnStatus);
					_connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fnSecurityError);
					_connection.connect(null);
				}
			}
		}
		
		/**
		 * Replay video (called from system in response to "replay")
		 */
		public function fnReplay():void
		{
			if ( _vastEnabled )
			{
				fnPlay();
				return;
			}
			
			// if no video then fade to end screen
			if (_videoFiles == null)
			{
				pStatus = "done";
			}
			else
			{
				pStatus = "playing";
				
				// trigger event
				_group.shellApi.triggerEvent("videoPlaying");
				
				// show full screen again
				//if (_fsVideo)
					//_fsVideo.replay();
				//else
				{
					_stream.seek(0);
					_stream.resume();
					
					// mute sounds
					_audioSystem.muteSounds();
				}
			}
		}
		
		/**
		 * Get status of stream or connection
		 * @param	aEvent
		 */
		private function fnStatus(aEvent:NetStatusEvent):void
		{
			//trace(aEvent.info.code);
			switch (aEvent.info.code) {
				case "NetConnection.Connect.Success":
					// successful connection, now connect stream
					fnConnectStream();
					break;
				case "NetStream.Play.StreamNotFound":
					// video not found
					trace("PopVideo :: Unable to locate video: " + _videoFile);
					// clear video file and fade to end screen
					_videoFile = null;
					pStatus = "done";
					break;
				case "NetStream.Play.Stop":
					// video reaches end
					fnVideoDone();
					break;
				case "NetStream.Seek.Complete":
					_videoPlayer.visible = true;
					break;
			}
		}
		
		/**
		 * Connect stream after connection is made
		 */
		private function fnConnectStream():void
		{
			// set up stream
			_stream = new NetStream(_connection);
			_stream.addEventListener(NetStatusEvent.NET_STATUS, fnStatus);
			_stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, fnAsyncError);
			
			// set buffer to 0.1 seconds
			_stream.bufferTime = 0.1;
			
			// metadata
			var vMetaData:Object=new Object();
			vMetaData.onMetaData = fnMetaData;
			_stream.client = vMetaData;
			
			_videoPlayer = new Video(_videoWidth, _videoHeight);
			_videoClip = _container.addChild(_videoPlayer);			

			_videoPlayer.attachNetStream(_stream);
			
			if ( _videoFile.toLowerCase().indexOf("http") == -1 )
			{
				var server:String = "https://" + _group.shellApi.siteProxy.fileHost + "/";
				trace("PopVideo :: Playing video: " + server + _videoFile);
				_stream.play(server + _videoFile);
			}
			else
				_stream.play(_videoFile);
			
			// mute sounds
			_audioSystem.muteSounds();
			
			// trigger event
			_group.shellApi.triggerEvent("videoPlaying");
		}
				
		/**
		 * Video is done
		 */
		private function fnVideoDone():void
		{	
			// if card video power then notify popup class
			// reworded for simplicity _RAM
			if (_group.hasOwnProperty('doneVideo')) {
				_group['doneVideo']();
			}
				
			pStatus = "done";
						
			//if (_fsVideo == null)
			{
				_videoPlayer.visible = false;
				// restore sounds
				_audioSystem.unMuteSounds();
			}			
			// trigger event
			_group.shellApi.triggerEvent("videoDone");
		}
		
		/**
		 * Stop video (called from system when another video is playing)
		 * @param	aEvent
		 */
		public function fnStop():void
		{
			//if (_fsVideo)
			//	_fsVideo.stop();
			//else
			{
				if (_stream != null)
				{
					pStatus = "end";
					_stream.pause();
					_videoPlayer.visible = false;
				}
			}
		}
		
		/**
		 * Pause video (called from game)
		 * @param	aEvent
		 */
		public function fnPause():void
		{
			//if (_fsVideo)
			//	_fsVideo.pause();
			//else
			{
				if ((_stream != null) && (pStatus == "playing"))
				{
					pStatus = "paused";
					_stream.pause();
				}
			}
		}

		/**
		 * Unpause video (called from game)
		 * @param	aEvent
		 */
		public function fnUnpause():void
		{
			//if (_fsVideo)
			//	_fsVideo.unpause();
			//else
			{
				if ((_stream != null) && (pStatus == "paused"))
				{
					pStatus = "playing";
					_stream.resume();
				}
			}
		}
		
		/**
		 * dispose video
		 * @param	aEvent
		 */
		public function fnDispose():void
		{
			//if (_fsVideo)
			//	_fsVideo.dispose();
			//else
			{
				if (_stream != null)
				{
					_stream.close();
					_videoPlayer.visible = false;
				}
				
				if (_connection != null)
					_connection.close();
				
				if ((_videoClip) && (_videoClip.parent))
					_videoClip.parent.removeChild(_videoClip);
				
				// restore sounds if playing
				if (pStatus == "playing")
				{
					_audioSystem.unMuteSounds();
				}
			}
		}
		
		// UTILITY FUNCTIONS ///////////////////////////////////////////////////////////////////////
		
		/**
		 * Get Meta Data
		 * @param	aMetaData
		 */
		private function fnMetaData(aMetaData:Object):void
		{
			trace("PopVideo :: Dimensions: " + aMetaData.width + " x " + aMetaData.height);
			_videoDuration = int(aMetaData.duration);
		}
		
		/**
		 * Security Errors
		 * @param	aEvent
		 */
		private function fnSecurityError(aEvent:SecurityErrorEvent):void
		{
			trace("PopVideo :: Security Error: " + aEvent);
		}
		
		/**
		 * Asynchronous Errors
		 * @param	aEvent
		 */
		private function fnAsyncError(aEvent:AsyncErrorEvent):void
		{
			trace("PopVideo :: Async Error: " + aEvent);
		}
	}
}
