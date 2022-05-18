package game.adparts.parts
{
	import com.poptropica.AppConfig;
	
	import flash.display.MovieClip;
	import flash.display.Stage;
	import flash.events.AsyncErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.StageVideoEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Rectangle;
	import flash.media.StageVideo;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.system.System;
	import flash.utils.getQualifiedClassName;
	
	import ash.core.Entity;
	
	import engine.ShellApi;
	import engine.components.Display;
	import engine.group.Group;
	import engine.systems.AudioSystem;
	
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.ads.AdTrackingConstants;
	import game.data.ui.ToolTipType;
	import game.managers.ScreenManager;
	import game.managers.ads.AdManager;
	import game.systems.ui.CursorSystem;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.utils.AdUtils;
	
	public class AdFullScreenVideo
	{
		private var useWeb:Boolean = false;
		
		public function AdFullScreenVideo(group:Group, useStageVideo:Boolean = true, notify:Function=null):void
		{
			_group = group;
			_shellApi = group.shellApi;
			_notify = notify;
			_status = "";
			if ((_shellApi.screenManager.stageVideoAvailable) && (useStageVideo))
			{
				trace("FullScreen Video: stage video available");
				_useStageVideo = true;
			}
			else
			{
				trace("FullScreen Video: stage video unavailable");
				// don't hide shell so cursor will appear
				_hideShell = false;
			}
			
			// TODO :: This should be handled by FileManager or DataStore. - bard
			if (_shellApi.siteProxy) {
				// if mobile or local, then pull server from comm.xml
				_server = "https://" + _shellApi.siteProxy.fileHost + "/";
			}
			// if browser, then use host server
			if ((!PlatformUtils.isMobileOS) && (PlatformUtils.inBrowser))
				_server = "/";
		}
		
		/**
		 * play video, called from game
		 */
		public function play():void
		{
			// load overlay first
			loadOverlay();
		}
		
		/**
		 * load overlay
		 */
		public function loadOverlay():void
		{
			trace("AdFullScreenVideo :: loadOverlay");
			_shellApi.log("AdFullScreenVideo :: loadOverlay",null,false);
			_videoStarted = false;
			// get stage and number of children
			_stage = (_shellApi.screenManager).sceneContainer.stage;
			_stageChildren = _stage.numChildren;
			
			if (PlatformUtils.inBrowser) {
				useWeb = true;
				_hideShell = true;
				_status = "playing";
				// setup callbacks
				ExternalInterface.addCallback("videoComplete", videoComplete);
				ExternalInterface.addCallback("videoClose", videoClose);
				ExternalInterface.addCallback("videoSponsor", videoSponsor);
				// mute audio
				_audioSystem = AudioSystem(_group.getSystem(AudioSystem));
				_audioSystem.muteSounds();
				// show overlay
				ExternalInterface.call("showVideoOverlay", _campaignName, (_server + _videoURL), _locked, _controls);
				// notify that we have started
				if (_notify != null)
				{
					if (_replaying)
						_notify(REPLAYED);
					else
						_notify(STARTED);
				}
				showShell(false);
				// pause
				_shellApi.currentScene.pause();
			} else {
				// load overlay
				_overlayLoaded = false;
				_shellApi.loadFile(_shellApi.assetPrefix + "ui/video/videoOverlay.swf", overlayLoaded);
			}
		}
		
		private function videoComplete():void {
			_status = "ended";
			_shellApi.currentScene.unpause();
			commonCleanup();
			if (_notify)
				_notify(ENDED);
		}
		
		private function videoClose():void {
			// track that button was clicked
			AdManager(_shellApi.adManager).track(_campaignName, AdTrackingConstants.TRACKING_VIDEO_CLOSED, _choice, _containerName);
			_status = "ended";
			_shellApi.currentScene.unpause();
			commonCleanup();
			if (_notify)
				_notify(QUIT);
		}
		
		private function videoSponsor():void {
			AdManager(_shellApi.adManager).track(_campaignName, AdTrackingConstants.TRACKING_CLICK_TO_SPONSOR, _choice, _containerName);
			AdUtils.openSponsorURL(_shellApi,_clickURL, _campaignName, _choice, _containerName);
		}
		
		/**
		 * video overlay loaded
		 * @param	asset	overlay movieClip
		 */
		private function overlayLoaded(asset:MovieClip):void
		{
			trace("AdFullScreenVideo :: overlayLoaded");
			_shellApi.log("AdFullScreenVideo :: overlayLoaded", null, false);

			// force click cursor
			var cursorSystem:CursorSystem = CursorSystem(_group.getSystem(CursorSystem));
			if (cursorSystem != null)
				cursorSystem.forceValidation();
			
			_overlayLoaded = true;
			
			// setup progress bar
			_progressBar = asset.progressBar;
			if (_progressBar)
			{
				_progressBar.bar.width = 0;
			}
			
			// if stage video load overlay onto stage
			if (_useStageVideo)
			{
				_videoOverlay = MovieClip(_stage.addChild(asset));
				// hide video back
				_videoOverlay.videoBack.visible = false;
			}
			else 
			{
				// else load into scene container so cursor will work
				// if hiding shell for standard video
				if (_hideShell)
					_videoOverlay = MovieClip(_stage.addChild(asset));
				else
				{
					_videoOverlay = MovieClip((_shellApi.screenManager).sceneContainer.addChild(asset));
				}
			}
			
			// fill device with overlay of 960x640
			var rect:Rectangle = fitRectToDevice(ScreenManager.GAME_WIDTH, ScreenManager.GAME_HEIGHT);
			
			// if not mobile, then swallow clicks and prevent cursor updates behind video
			if (!AppConfig.mobile)
			{
				// swallow clicks in standard video, so clicks don't trigger layers below
				_videoClicksEntity = ButtonCreator.createButtonEntity( _videoOverlay.videoContainer, _group, swallowClicks, null, null, ToolTipType.CLICK);
			}
			else 
			{
				// if mobile then position and scale
				_videoOverlay.x = rect.x;
				_videoOverlay.y = rect.y;
				_videoOverlay.scaleX = rect.width/ScreenManager.GAME_WIDTH;
				_videoOverlay.scaleY = rect.height/ScreenManager.GAME_HEIGHT;
				trace("videooverlay x:" + _videoOverlay.x + " videooverlay y: " + _videoOverlay.y);				
				_shellApi.log("videooverlay x:" + _videoOverlay.x + " videooverlay y: " + _videoOverlay.y, null, false);

			}
			
			// hide overlay until needed
			_videoOverlay.visible = false;
			
			_videoOverlay.btnCancel.visible = false;
			_videoOverlay.confirmDialog.visible = false;
			
			// create interaction for clicking on end button
			// note that if the overlay is added to desktop, no cursors will update
			if (_locked)
				_videoOverlay.btnClose.visible = false;
			else
				ButtonCreator.createButtonEntity( _videoOverlay.btnClose, _group, videoQuit);
			
			// setup visit site button if click URL isn't empty
			if (_clickURL != "" && !_suppressSponsorButton)
			{
				ButtonCreator.createButtonEntity( _videoOverlay.btnVisit, _group, showDialog);
			}
			else
			{
				// else hide it
				_videoOverlay.btnVisit.visible = false;
			}
			
			// setup cancel button
			_cancelButton = ButtonCreator.createButtonEntity( _videoOverlay.btnCancel, _group, hideDialog);
			_cancelButton.get(Display).visible = false;
			
			// setup like button
			if (_showLikeButton)
			{
				ButtonCreator.createButtonEntity( _videoOverlay.btnLike, _group, likeVideo);
			}
			else
			{
				_videoOverlay.btnLike.visible = false;
			}
			
			// try to start video
			// setup connection once
			if (!_connected)
			{
				
				_connected = true;
				_connection = new NetConnection();
				_connection.addEventListener(NetStatusEvent.NET_STATUS, fnStatus);
				_connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fnSecurityError);
				_connection.connect(null);
			}
			else
			{
				_videoOverlay.visible = true;
				
				_stream.close();
				_stream.dispose();
				// reattach stream
				if (_useStageVideo) {
					_stageVideo.attachNetStream(_stream);
				}
				else {
					_video.attachNetStream(_stream);
				}
				
				// begin streaming again
				_stream.play(_server + _videoURL);
				
				// mute sounds again
				_audioSystem.muteSounds();
				
				showShell(false);
				
				// notify that we have started replay
				if (_notify)
					_notify(REPLAYED);
			}
		}
		
		/**
		 * video status
		 * @param	aEvent
		 */
		private function fnStatus(aEvent:NetStatusEvent):void
		{
			trace("FullScreen Video Player: status: " + aEvent.info.code);
			switch (aEvent.info.code)
			{
				case "NetConnection.Connect.Success":
					// successful connection, now connect stream
					connectStream();
					break;
				case "NetStream.Play.StreamNotFound":
					// video not found
					trace("FullScreen Video Player: Unable to locate video: " + _videoURL);
					// dispose video
					dispose();
					// notify function
					if (_notify)
						_notify(NOT_FOUND);
					break;
				case "NetStream.Play.Fail":
					// video fails
					videoFail();
					break;
				case "NetStream.Play.Stop":
					// video reaches end
					videoDone();
					break;
				case "NetStream.Seek.Complete": // not using seek anymore
					break;
			}
		}
		
		public function updateProgress():void
		{
			// replay will have stream time at 1.0, so wait until time is near zero
			if ((!_videoStarted) && (_stream != null) && (_stream.time < 0.1))
			{
				_videoStarted = true;
			}
			if (_videoStarted)
			{
				var videoProgress:Number = _stream.time / _videoDuration;
				if (videoProgress > 1.0)
					videoProgress = 1.0;
				if (_progressBar != null)
					_progressBar.bar.width = videoProgress * 960;				
			}
		}
		
		/**
		 * Connect stream after connection is made
		 */
		private function connectStream():void
		{
			_status = "playing";
			trace("Memory Stream not created, Free: " + System.freeMemory);
			trace("Memory Stream not created, Total: " + System.totalMemory);
			// set up stream
			_stream = new NetStream(_connection);
			_stream.addEventListener(NetStatusEvent.NET_STATUS, fnStatus);
			_stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, fnAsyncError);
			
			// set buffer to 0.4 second (was 0.2)
			_stream.bufferTime = 0.4;
			
			// metadata
			var vMetaData:Object=new Object();
			vMetaData.onMetaData = fnMetaData;
			_stream.client = vMetaData;
			
			// show video overlay now
			_videoOverlay.visible = true;
			
			if (_useStageVideo)
			{
				// use stage video from first slot
				_stageVideo = _stage.stageVideos[0];
				_stageVideo.addEventListener(StageVideoEvent.RENDER_STATE, onRender);
				_stageVideo.attachNetStream(_stream) ;
			}
			else
			{
				trace("AdFullScreenVideo :: connectStream : _useStageVideo false");
				_shellApi.log("AdFullScreenVideo :: connectStream : _useStageVideo false", null, false);

				// create video set to viewport size
				// note: this never happens on mobile because stageVideo is used
				_video = new Video(_shellApi.viewportWidth, _shellApi.viewportHeight);
				_videoOverlay.videoContainer.addChild(_video);
				_video.attachNetStream(_stream);
			}
			
			// hide stage but not video overlay
			showShell(false);
			
			// begin streaming
			trace("Memory Stream Connected, Free: " + System.freeMemory);
			trace("Memory Stream Connected, Total: " + System.totalMemory);
			_stream.play(_server + _videoURL);
			trace("FullScreen Video Player: Playing video: " + _server + _videoURL);
			
			// mute sounds
			_audioSystem = AudioSystem(_group.getSystem(AudioSystem));
			_audioSystem.muteSounds();
			
			// notify that we have started
			if (_notify)
			{
				if (_replaying)
					_notify(REPLAYED);
				else
					_notify(STARTED);
			}
		}
		
		/**
		 * replay current video
		 */
		public function replay():void
		{
			_status = "playing";
			_replaying = true;
			
			loadOverlay();
		}
		
		/**
		 * stop current video
		 */
		public function stop():void
		{
			if (useWeb)
			{
				_status = "ended";
			}
			else if (_stream != null)
			{
				_status = "ended";
				_stream.pause();
			}
		}
		
		/**
		 * pause current video
		 */
		public function pause():void
		{
			if ((useWeb) && (_status == "playing"))
			{
				_status = "paused";
			}
			else if ((_stream != null) && (_status == "playing"))
			{
				_status == "paused";
				_stream.pause();
			}
		}
		
		/**
		 * unpause current video
		 */
		public function unpause():void
		{
			if ((useWeb) && (_status == "paused"))
			{
				_status = "playing";
			}
			else if ((_stream != null) && (_status == "paused"))
			{
				_status == "playing";
				_stream.resume();
			}
		}
		
		/**
		 * when video completes
		 */
		private function videoDone():void
		{
			trace("Memory Stream not created, Free: " + System.freeMemory);
			trace("Memory video done, Total: " + System.totalMemory);
			cleanup();
			
			if (_notify)
				_notify(ENDED);
		}
		
		/**
		 * when video fails
		 */
		private function videoFail():void
		{
			cleanup();
			
			if (_notify)
				_notify(FAILED);
		}
		
		/**
		 * when video is quit by clicking on button
		 */
		private function videoQuit(entity:Entity):void
		{
			// track that button was clicked
			AdManager(_shellApi.adManager).track(_campaignName, AdTrackingConstants.TRACKING_VIDEO_CLOSED, _choice, _containerName);
			
			// if confirmation dialog is vislble then send tracking call for canceling the dialog
			if (_videoOverlay.confirmDialog.visible)
				hideDialog();
			
			// stop stream
			if (_stream)
				_stream.pause();
			
			cleanup();
			
			if (_notify)
				_notify(QUIT);
		}
		
		/**
		 * cleanup video
		 */
		private function cleanup():void
		{
			// remove video latent image
			if (_useStageVideo)
			{
				_stageVideo.attachNetStream(null);
			}
			else
			{
				_video.attachNetStream(null);
				_connected = false;
			}
			
			commonCleanup();
			
			_status = "ended";
		}
		
		/**
		 * dispose of video
		 */
		public function dispose(entity:Entity = null):void
		{
			if (_stream != null) {
				_stream.close();
				_stream.dispose();
			}
			
			if (_connection != null)
				_connection.close();
			
			commonCleanup();
		}
		
		// common cleanup
		private function commonCleanup():void
		{
			// dispose video overlay
			if ((_overlayLoaded) && (_videoOverlay))
			{
				_videoOverlay.parent.removeChild(_videoOverlay);
				//_videoOverlay = null;
				_overlayLoaded = false;
				//_videoOverlay.visible = false;
			}
			
			// remove video clicks entity
			if (_videoClicksEntity != null)
				_group.removeEntity(_videoClicksEntity);
			
			// restore shell if stage video
			showShell(true);
			
			// restore sounds if playing
			if ((_status == "playing") || (useWeb))
			{
				_audioSystem.unMuteSounds();
			}
		}
		
		private function showDialog(entity:Entity):void
		{
			if (PlatformUtils.isMobileOS)
			{
				// skip if mobile and no network
				if (!_shellApi.networkAvailable())
					return;
				
				_videoOverlay.confirmDialog.visible = true;
				_cancelButton.get(Display).visible = true;
				
				// setup delay
				_timer = SceneUtil.addTimedEvent(_group, new TimedEvent( _delay, 1, onTimeout ), "leavingPop");
			}
			else
			{
				onTimeout();
			}
		}
		
		private function onTimeout():void
		{
			if (PlatformUtils.isMobileOS)
				hideDialog();
			
			//var videoArray:Array = _videoURL.split("/");
			//var videoName:String = videoArray[videoArray.length-1];
			//videoName = videoName.substr(0, videoName.indexOf("."));
			
			// used to pass video name, now pass container name
			AdManager(_shellApi.adManager).track(_campaignName, AdTrackingConstants.TRACKING_CLICK_TO_SPONSOR, _choice, _containerName);
			AdUtils.openSponsorURL(_shellApi,_clickURL, _campaignName, _choice, _containerName);
		}
		
		private function hideDialog(btnEntity:Entity = null):void
		{
			_videoOverlay.confirmDialog.visible = false;
			_cancelButton.get(Display).visible = false;
			_timer.stop();
			_timer = null;
			
			// if video has ended then cleanup
			if (_status == "ended")
				cleanup();
		}
		
		private function likeVideo(entity:Entity):void
		{
			// go to frame 2
			entity.get(Timeline).gotoAndStop(1);
			
			// tracking
			var videoArray:Array = _videoURL.split("/");
			var videoName:String = videoArray[videoArray.length-1];
			videoName = videoName.substr(0, videoName.indexOf("."));
			AdManager(_shellApi.adManager).track(_campaignName, AdTrackingConstants.TRACKING_VIDEO_LIKE, "VideoOverlay", videoName);
		}
		
		// UTILITY FUNCTIONS ///////////////////////////////////////////////////////////////////////
		
		/**
		 * set rect to fit device for overlay or video
		 */
		private function fitRectToDevice(width:Number, height:Number):Rectangle
		{// target proportions for device
			var targetProportions:Number = _stage.fullScreenWidth/_stage.fullScreenHeight;
			var destProportions:Number = width/height;
			var x:Number = 0;
			var y:Number = 0;
			// if wider, then fit to width and center vertically
			if (destProportions >= targetProportions)
			{
				var scale:Number = _stage.fullScreenWidth/width;
				width *= scale;
				height *= scale;
				y = (_stage.fullScreenHeight - height) / 2;
			}
			else 
			{
				// else fit to height and center horizontally
				scale = _stage.fullScreenHeight/height;
				width *= scale;
				height *= scale;
				x = (_stage.fullScreenWidth - width) / 2;
			}
			trace("AdFullScreenVideo :: fitRectToDevice: rect: " + x+" " + y + " " + width + " " + height );
			_shellApi.log("AdFullScreenVideo :: fitRectToDevice: rect: " + x+" " + y + " " + width + " " + height, null, false );

			return new Rectangle(x, y, width, height);

		}
		
		private function fitRectToOverlay(width:Number, height:Number):Rectangle
		{
			// target proportions for overlay
			var targetProportions:Number = ScreenManager.GAME_WIDTH/ScreenManager.GAME_HEIGHT;
			var destProportions:Number = width/height;
			var x:Number = 0;
			var y:Number = 0;
			// if wider, then fit to width and center vertically
			if (destProportions >= targetProportions)
			{
				var scale:Number = ScreenManager.GAME_WIDTH/width;
				width *= scale;
				height *= scale;
				y = (ScreenManager.GAME_HEIGHT - height) / 2;
			}
			else
			{
				// else fit to height and center horizontally
				scale = ScreenManager.GAME_HEIGHT/height;
				width *= scale;
				height *= scale;
				x = (ScreenManager.GAME_WIDTH - width) / 2;
			}
			if( _videoOverlay )
			{
				return new Rectangle(_videoOverlay.x + x*_videoOverlay.scaleX, _videoOverlay.y + y*_videoOverlay.scaleY, width*_videoOverlay.scaleX, height*_videoOverlay.scaleY);
				trace("AdFullScreenVideo :: fitRectTooverlay: rect: " + _videoOverlay.x + x*_videoOverlay.scaleX+" " + _videoOverlay.y + y*_videoOverlay.scaleY + " " + width*_videoOverlay.scaleX + " " + height*_videoOverlay.scaleY );
				_shellApi.log("AdFullScreenVideo :: fitRectTooverlay: rect: " + _videoOverlay.x + x*_videoOverlay.scaleX+" " + _videoOverlay.y + y*_videoOverlay.scaleY + " " + width*_videoOverlay.scaleX + " " + height*_videoOverlay.scaleY, null, false );

			}
			else
			{
				trace( this," :: ERROR :: fitRectToOverlay : _videoOverlay was null, needs to be defined.");
				_shellApi.log( " :: ERROR :: fitRectToOverlay : _videoOverlay was null, needs to be defined.", null, false);
				return null;
			}
		}
		
		/**
		 * swallow mouse clicks on standard video
		 */
		private function swallowClicks(entity:Entity):void
		{
		}
		
		/**
		 * show/hide shell (stage children)
		 * @param	state	on/off
		 */
		private function showShell(state:Boolean):void
		{
			// if using stage video or hiding shell for standard video
			if ((_useStageVideo) || (_hideShell))
			{
				for (var i:int = 0; i!= _stageChildren; i++)
					_stage.getChildAt(i).visible = state;
			}
		}
		
		/**
		 * when rendering stage video (use full viewport)
		 * @param	aEvent	stageVideoEvent
		 */
		private function onRender(aEvent:StageVideoEvent = null):void
		{
			trace("FullScreen Video Player: Render video: " + _width + "," + _height);
			_shellApi.log("FullScreen Video Player: Render video: " + _width + "," + _height, null, false);
			// if stage video and valid width
			if ((_useStageVideo) && (!isNaN(_width)))
			{
				rendered = true;
				_stageVideo.viewPort = fitRectToOverlay(_width, _height);
				
			}
		}
		
		/**
		 * Get Meta Data
		 * @param	aMetaData
		 */
		private function fnMetaData(aMetaData:Object):void
		{
			trace("FullScreen Video Player: Dimensions: " + aMetaData.width + " x " + aMetaData.height);
			_shellApi.log("FullScreen Video Player: Dimensions: " + aMetaData.width + " x " + aMetaData.height, null, false);
			// remember dimensions
			_width = aMetaData.width;
			_height = aMetaData.height;
			_videoDuration = aMetaData.duration;
			
			// render if not rendered
			if (!rendered)
				onRender();
			
			if (!_useStageVideo)
			{
				// resize video to match actual video dimensions and fit to device
				/*
				var rect:Rectangle = fitRectToDevice(_width, _height);
				_video.x = rect.x;
				_video.y = rect.y;
				_video.width = rect.width;
				_video.height = rect.height;
				*/
				_video.width = _width
				_video.height = _height;
			}
			
		}
		
		/**
		 * Security Errors
		 * @param	aEvent
		 */
		private function fnSecurityError(aEvent:SecurityErrorEvent):void
		{
			trace("FullScreen Video Player: Security Error: " + aEvent);
		}
		
		/**
		 * Asynchronous Errors
		 * @param	aEvent
		 */
		private function fnAsyncError(aEvent:AsyncErrorEvent):void
		{
			trace("FullScreen Video Player: Async Error: " + aEvent);
		}
		
		/**
		 * Set video URL and appropriate extension if Android
		 * @param videoFile
		 */
		public function set videoURL(videoFile:String):void
		{			
			// use m4v only now (no need for flv for iOS anymore)
			//_videoURL = videoFile.replace(".flv",".m4v");
			// restored this because m4v always plays back the first time
			_videoURL = ( PlatformUtils.isAndroid ) ? videoFile.replace(".flv",".m4v") : videoFile;
		}
		
		public function set clickURL(sponsorURL:String):void { _clickURL = sponsorURL; }
		public function set campaignName(campaign:String):void { _campaignName = campaign; }
		public function set showLikeButton(state:Boolean):void { _showLikeButton = state; }
		public function set locked(state:Boolean):void { _locked = state; }
		public function set controls(state:Boolean):void { _controls = state; }
		public function set suppressSponsorButton(state:Boolean):void { _suppressSponsorButton = state; }
		public function set containerName(name:String):void { _containerName = name; }
		
		private var _server:String;	// TODO :: this should be managed in CommunicationData. - bard
		private var _useStageVideo:Boolean = false;
		private var _shellApi:ShellApi;
		private var _notify:Function;
		private var _group:Group;
		private var _stage:Stage;
		private var _stageChildren:int;
		private var _overlayLoaded:Boolean = false;
		private var _status:String;
		private var _audioSystem:AudioSystem;
		private var _hideShell:Boolean = true; // use to hide shell when playing standard video (cursors don't work in this mode - ok for mobile)
		private var _clickURL:String;
		private var _choice:String = "Video";
		private var _containerName:String;
		private var _campaignName:String;
		private var _cancelButton:Entity;
		private var _showLikeButton:Boolean = false;
		private var _locked:Boolean = false;
		private var _controls:Boolean = false;
		private var _suppressSponsorButton:Boolean = false;
		private var _connected:Boolean = false;
		private var _replaying:Boolean = false;
		private var _timer:TimedEvent;
		private var _progressBar:MovieClip;
		private var _videoStarted:Boolean = false;
		private var _videoClicksEntity:Entity;
		
		// video variables
		private var _videoURL:String;
		private var _connection:NetConnection;
		private var _stream:NetStream;
		private var _stageVideo:StageVideo;
		private var _video:Video;
		private var _videoOverlay:MovieClip;
		private var _width:Number;
		private var _height:Number;
		private var _videoDuration:Number;
		
		public static const NOT_FOUND:String = "not found";
		public static const STARTED:String = "started";
		public static const REPLAYED:String = "replayed";
		public static const ENDED:String = "ended";
		public static const FAILED:String = "failed";
		public static const QUIT:String = "quit";
		
		private const _delay:int = 1;
		private var rendered:Boolean = false;
	}
}