package game.ui.elements {

import flash.display.Sprite;
import flash.events.IOErrorEvent;

public class PoptropicaYouTubePlayer extends Sprite {

	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.system.Security;
	import org.osflash.signals.Signal;

	public static const DEFAULT_WIDESCREEN_WIDTH:Number		= 854;
	public static const DEFAULT_ACADEMY_WIDTH:Number		= 640;
	public static const DEFAULT_VIDEO_HEIGHT:Number			= 480;

    private static const SECURITY_DOMAIN:String = "https://www.youtube.com";
    private static const CHROMELESS_PLAYER_URL:String = "https://www.youtube.com/apiplayer?version=3";

	private static const STATE_UNSTARTED:int	= -1;
	private static const STATE_ENDED:int		= 0;
	private static const STATE_PLAYING:int		= 1;
	private static const STATE_PAUSED:int		= 2;
	private static const STATE_BUFFERING:int	= 3;
	private static const STATE_CUED:int			= 5;

	public static function nameForState(aState:int):String {
		var theName:String = 'unknown';
		var stateNames:Array = ['ended', 'playing', 'paused', 'buffering', '', 'cued'];
		if (-1 == aState) {
			theName = 'unstarted';
		} else if ((-1 < aState) && (stateNames.length > aState)) {
			theName = stateNames[aState];
		}
		return theName;
	}

	public var isChromeless:Boolean = true;
	public var playerReady:Signal;

	private var playerLoader:Loader;
	private var player:Object;
	private var videoCode:String;
	private var videoURL:String;
	private var playerRect:Rectangle;

	//// CONSTRUCTOR ////

	public function PoptropicaYouTubePlayer() {
		size = new Rectangle(0,0, DEFAULT_WIDESCREEN_WIDTH, DEFAULT_VIDEO_HEIGHT);
		playerLoader = new Loader();
		playerLoader.contentLoaderInfo.addEventListener(Event.INIT, playerLoaderInitHandler);
		Security.allowDomain(SECURITY_DOMAIN);
		playerReady = new Signal();
	}

	//// ACCESSORS ////

	public function get playerState():int {
		return int(player.getPlayerState());
	}

	public function set size(newSize:Rectangle):void {
		playerRect = newSize;
		// the Google YouTube player exhibits some pretty nasty visual artifacts
		// when it begins playback. The best way to hide these dirty update regions
		// is to provide a black backdrop graphic for the player's rect.
		with (graphics) {
			clear();
			beginFill(0x0);
			drawRect(playerRect.left, playerRect.top, playerRect.width, playerRect.height);
		}
	}

	public function get videoID():String {
		return videoCode;
	}
	public function set videoID(newID:String):void {
		videoCode = newID;
		if (isChromeless) {
			videoURL = CHROMELESS_PLAYER_URL;
		} else {
			videoURL = 'http://www.youtube.com/v/' + videoCode + '?version=3';
		}
		var req:URLRequest = new URLRequest(videoURL);
		playerLoader.load(req);
	}

	public function get percentLoaded():Number {
		return player.getVideoLoadedFraction();
	}

	//// PUBLIC METHODS ////

	public function pausePlayer(flag:Boolean=true):void {
		if (flag) {
			player.pauseVideo();
		} else {
			player.playVideo();
		}
	}

	public function destroy():void {
		pausePlayer();
		playerReady.removeAll();
		player.destroy();
	}

	public function logWWW(...msgs):void {
		var dbugStr:String = msgs.join(' ');
		if (ExternalInterface.available) {
			ExternalInterface.call('dbug', dbugStr);
		}
		trace(dbugStr);
	}

	//// INTERNAL METHODS ////

	//// PROTECTED METHODS ////

	//// PRIVATE METHODS ////

    private function playerLoaderInitHandler(event:Event):void {
		event.currentTarget.removeEventListener(Event.INIT, playerLoaderInitHandler);
		
		addChild(playerLoader);
		playerLoader.content.addEventListener("onReady",					onPlayerReady);
		playerLoader.content.addEventListener("onError",					onPlayerError);
		playerLoader.content.addEventListener("onStateChange",				onPlayerStateChange);
		playerLoader.content.addEventListener("onPlaybackQualityChange",	onVideoPlaybackQualityChange);

		var mouseCatcher:Sprite = new Sprite();
		with (mouseCatcher.graphics) {
			beginFill(0x0, 0.0);
			drawRect(playerRect.left, playerRect.top, playerRect.width, playerRect.height);
		}
		addChild(mouseCatcher);
    }

    private function onPlayerReady(event:Event):void {
		player = playerLoader.content;
		player.setSize(playerRect.width, playerRect.height);
		player.x = playerRect.left;
		player.y = playerRect.top;
		player.cueVideoById(videoID);

		addEventListener(MouseEvent.CLICK, onVideoClick);
		playerReady.dispatch();
    }

    private function onPlayerError(event:Event):void {
      logWWW("Player error:", Object(event).data);
    }

	private function onPlayerStateChange(e:Event):void {
		var newState:int = Object(e).data;
		trace("YouTube state is", nameForState(newState));
		if (STATE_ENDED == newState) {
			player.cueVideoById(videoID);
		}
	}

	private function onVideoPlaybackQualityChange(e:Event):void {
		//logWWW("Quality changed to", Object(e).data);
	}

	private function onVideoClick(e:MouseEvent):void {
		var currentVideoState:Number = playerState;
		//logWWW("click in state", nameForState(currentVideoState));
		switch (currentVideoState) {
			case STATE_PLAYING:
			case STATE_BUFFERING:
				pausePlayer(true);
				break;
			case STATE_UNSTARTED:
			case STATE_PAUSED:
			case STATE_ENDED:
			case STATE_CUED:
				pausePlayer(false);
				break;
			default:
				break;
		}
	}

}

}
