package game.managers.ads
{
	import com.milkmangames.nativeextensions.AdMob;
	import com.milkmangames.nativeextensions.events.AdMobErrorEvent;
	import com.milkmangames.nativeextensions.events.AdMobEvent;
	
	import flash.display.Sprite;
	
	import engine.ShellApi;
	import engine.systems.AudioSystem;
	
	/**
	 * Network ads manager for AdMob
	 * @author Rick Hocker
	 */
	public class AdManagerNetwork
	{
		// adMob
		private const PUBLISHER_ID:String = "pub-2910945647025446";
		private const ANDROID_ID:String = "ca-app-pub-2910945647025446~6399512816";
		private const IOS_ID:String = "ca-app-pub-2910945647025446~7876246010";
		private const ANDROID_INTERSTITIAL_ID:String = "ca-app-pub-2910945647025446/4749903389";		
		private const IOS_INTERSTITIAL_ID:String = "ca-app-pub-2910945647025446/7943514413";
		
		private var shellApi:ShellApi;
		private var nextScene:Function;
		private var interstitialActive:Boolean = false;
		private var pauseGame:Boolean = false;

		public function AdManagerNetwork()
		{
		}
		
		public function init(nextScene:Function):Boolean
		{
			var currAppId: String;
			
			// remember next scene function
			this.nextScene = nextScene;
			
			if(AdMob.isSupported)
			{
				trace("Network ads: Initializing AdMob");
				AdMob.init(ANDROID_INTERSTITIAL_ID, IOS_INTERSTITIAL_ID);
				AdMob.setChildDirected(true);
				// NOTE: when enabling test device IDs, I got an error with the trimmed Google Play Services ANE
				// GoogleService failed to initialize, status: 10, Missing an expected resource: 'R.string.google_app_id'
				// AdMob.enableTestDeviceIDs(AdMob.getCurrentTestDeviceIDs()); // remember to remove this
				AdMob.addEventListener(AdMobErrorEvent.FAILED_TO_RECEIVE_AD, onFailedReceiveAd);
				AdMob.addEventListener(AdMobEvent.RECEIVED_AD, onReceiveAd);
				AdMob.addEventListener(AdMobEvent.SCREEN_PRESENTED,onScreenPresented);
				AdMob.addEventListener(AdMobEvent.SCREEN_DISMISSED,onScreenDismissed);
			}
			else
			{
				trace("Network ads: Not supported");
				return false;
			}

			return true;
		}

		/**
		 * Load network ad when door reached
		 */
		public function loadAd(shellApi:ShellApi, settings:Boolean):void
		{
			this.shellApi = shellApi;
			pauseGame = settings;
			
			trace("Network ads: load");
			
			// load interstitial
			if (AdMob.isInterstitialReady())
			{
				var success:Boolean = true;
				try
				{
					AdMob.showPendingInterstitial();
				}
				catch (e:Error)
				{
					trace("Network ads: interstitial request failed");
					success = false;
					nextScene(true);
				}
				if (success)
				{
					// set black
					var blackOverlay:Sprite = shellApi.sceneManager.currentScene.screenEffects.createBox(shellApi.viewportWidth, shellApi.viewportHeight);
					shellApi.sceneManager.currentScene.overlayContainer.addChild(blackOverlay);
					// mute sounds
					AudioSystem(shellApi.sceneManager.currentScene.getSystem(AudioSystem)).muteSounds();
				}
			}
			else
			{
				trace("Network ads: interstitial not ready");
				nextScene(true);
			}
		}
		
		/** On Failed Receive Ad */
		private function onFailedReceiveAd(e:AdMobErrorEvent):void
		{
			trace("Network ads: ERROR receiving ad: " + e.text);
			// error can be "Request Error: No ad to show"
			// if interstitial then go to next scene
			if (e.isInterstitial)
				nextScene(false);
		}
		
		/** On Receive Ad */
		private function onReceiveAd(e:AdMobEvent):void
		{
			trace("Network ads: Received ad: " + e.isInterstitial);
		}
		
		/** On Screen Presented */
		private function onScreenPresented(e:AdMobEvent):void
		{
			trace("Network ads: Screen Presented.");
			// pause game if pause mode
			if (pauseGame)
				shellApi.pause();
			interstitialActive = true;
		}
		
		/** On Screen Dismissed */
		private function onScreenDismissed(e:AdMobEvent):void
		{
			trace("Network ads: Screen Dismissed.");
			interstitialActive = false;
			nextScene(true);
		}
		
		public function handleSceneLoaded(island:String):void
		{
			// mute sounds if interstitial active
			if (interstitialActive)
				AudioSystem(shellApi.sceneManager.currentScene.getSystem(AudioSystem)).muteSounds();
			
			if ((island != "start") && (island != "map"))
			{
				// preload next ad if none waiting
				if (!AdMob.isInterstitialReady())
				{
					trace("Network ads: Preload interstitial.");
					AdMob.setChildDirected(true);
					AdMob.loadInterstitial(ANDROID_INTERSTITIAL_ID, false, IOS_INTERSTITIAL_ID);
				}
				else
				{
					trace("Network ads: interstitial already preloaded.");
				}
			}
		}
	}
}