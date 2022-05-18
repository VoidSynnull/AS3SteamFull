package game.ui.hud
{
	import com.greensock.TweenMax;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	
	import ash.core.Entity;
	
	import engine.ShellApi;
	import engine.components.Spatial;
	import engine.group.DisplayGroup;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.data.profile.ProfileData;
	import game.managers.LanguageManager;
	import game.proxy.ITrackingManager;
	import game.proxy.TrackingManager;
	import game.scene.template.SceneUIGroup;
	import game.scene.template.ads.AdInteriorScene;
	import game.scenes.ftue.intro.Intro;
	import game.scenes.hub.profile.Profile;
	import game.scenes.hub.store.Store;
	import game.scenes.lands.lab1.Lab1;
	import game.ui.elements.ConfirmationDialogBox;
	import game.ui.popup.MembershipPopup;
	import game.ui.saveGame.RealmsRedirectPopup;
	import game.ui.saveGame.SaveGamePopup;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	
	public class HudPopBrowser extends Hud
	{
		// dialog messages
		private static const GO_TO_FRIENDS:String			= "go to Friends?";
		private static const GO_TO_REALMS:String			= "\rleave this island and\rgo to Poptropica Realms?";
		private static const GO_TO_SAVE:String				= "save?";
		
		private static const GO_TO_REALMS_REGISTER:String	= "To enter Poptropica Realms\ryou must save your game.\r";
		private static const GO_TO_FRIENDS_REGISTER:String	= "To visit your profile page\ryou must save your game.\r";
		
		private const REGISTER_FOR_RELAMS:String = "RegisterForRealms";
		
		private var _flashBulbEntity:Entity;
		
		public function HudPopBrowser(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		///////////////////////////////////////// MAP BUTTON /////////////////////////////////////////
		/* this is no longer being called
		private function goToTravelMap():void
		{
			// Platform check now happens in the Map popup itself.
			super.shellApi.loadScene((shellApi.sceneManager).gameData.mapClass);
			
			// backed out code for advertising changes
			//var onMain:Boolean = SceneUtil.isMainStreetClass(shellApi.sceneManager.currentScene);
			//askForConfirmation(CONFIRMATION_PREAMBLE + (onMain ? GO_TO_THE_MAP : GO_TO_MAIN_STREET));
		}
		*/
		///////////////////////////////////////// HOME BUTTON /////////////////////////////////////////
		
		/**
		 * FOR OVERRIDE : Creation Home hud button varies across platforms
		 * Functionality varies across platforms, so this is overridden by extending classes. 
		 * @param btnClip
		 * @param index
		 * @param name
		 * @param startSpatial
		 */
		/*		override protected function createHomeButton( btnClip:MovieClip, index:int, name:String, startSpatial:Spatial ):void 
		{
		// if player is guest, don't show the home button as this just ends up kicking them out of the experience
		if( shellApi.profileManager.active.isGuest )
		{
		if( btnClip )
		{
		btnClip.parent.removeChild(btnClip);
		}
		}
		else
		{
		super.createHomeButton( btnClip, index, name, startSpatial );
		}
		}*/
		/*		protected override function createHomeButton( btnClip:MovieClip, index:int, name:String, startSpatial:Spatial ):void
		{
		super.createHomeButton( btnClip, index, name, startSpatial );
		if (shellApi.profileManager.active.isGuest) {
		hideButton(Hud.HOME);
		}
		}*/
		
		///////////////////////////////////////// REALMS BUTTON /////////////////////////////////////////
		
		/**
		 * Create Friends hud button.
		 * Functionality varies across platforms, so this is overridden by extending classes. 
		 * @param btnClip
		 * @param index
		 * @param name
		 * @param startSpatial
		 */
		override protected function createRealmsButton( btnClip:MovieClip, index:int, name:String, startSpatial:Spatial ):void 
		{
			
			btnClip.x = startSpatial.x - (BUTTON_BUFFER * 5 - BUTTON_OFFSET);
			_friendsBtn = createHudButton( btnClip, index++, name, startSpatial, onRealmsClick );
		}
		
		/**
		 * BROWSER USE ONLY (FOR NOW)
		 * Will remain inactive until we have friends implementd on mobile 
		 * @param btn
		 */
		private function onRealmsClick( btn:Entity = null ):void 
		{
			if(shellApi.networkAvailable())
			{
				this.openRealms();
			}else
			{
				shellApi.showNeedNetworkPopup();
			}
			
		}
		
		public function openRealms():void
		{
			// For 220 Realms is broken for soem reason, denying access and just showing a warning
			/*
			//var text:String = "\nRealms is temporarily down for maintenance. Our apologies, it will be back soon!";
			//createHudDialogBox( 0, text, null, null, true );
			*/
			
			var text:String;
			if (!shellApi.profileManager.active.isGuest) 	
			{
				text = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.hud.realms", SceneUIGroup.CONFIRMATION_PREAMBLE + GO_TO_REALMS);
			}
			else
			{
				text = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.hud.realms", GO_TO_REALMS_REGISTER);
			}
			createHudDialogBox( 1, text, goToRealms );
		}
		
		/**
		 * @param btn
		 */
		private function goToRealms():void 
		{
			if (!shellApi.profileManager.active.isGuest) 
			{
				shellApi.track(REALMS + OPENED, null, null, SceneUIGroup.UI_EVENT);
				shellApi.loadScene(Lab1, 2100, 1000);
				var charLSO:SharedObject = ProxyUtils.as2lso;
				// this path doesn't go through the AS2 travelmap, so we modify the Char LSO from here
				charLSO.data.last_room = 'Lab1';
				charLSO.data.last_island = 'Lands';
				charLSO.flush();
			}
			else
			{
				showRegistrationForm(this);
			}
		}
		
		private function checkSaveForRealms(popup:RealmsRedirectPopup):void
		{
			if(popup.save)
				showRegistrationForm(this);
		}
		
		///////////////////////////////////////// FRIENDS BUTTON /////////////////////////////////////////
		
		/**
		 * BROWSER ONLY - this will be true until we have friends implementd on mobile 
		 * @param btn
		 * 
		 */
		override protected function goToFriends():void 
		{
			if (!shellApi.profileManager.active.isGuest) 
			{
				shellApi.track(FRIENDS + OPENED, null, null, SceneUIGroup.UI_EVENT);
				shellApi.loadScene(Profile);
			}
			else
			{
				var text:String = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.hud.friends", GO_TO_FRIENDS_REGISTER);
				createHudDialogBox( 1, text, Command.create(showRegistrationForm, this) );
			}
		}
		
		///////////////////////////////////////// STORE BUTTON /////////////////////////////////////////
		
		/**
		 * Open the store, currently diverts to AS2
		 * @param btn
		 */
		override protected function openStore():void 
		{
			shellApi.track(STORE + OPENED, null, null, SceneUIGroup.UI_EVENT);
			// do we need a notification popup here? - bard
			super.shellApi.loadScene(Store);
		}
		
		///////////////////////////////////////// HOME BUTTON /////////////////////////////////////////
		
		override protected function goToHome():void 
		{
			// DEBUG :: this really shoudln;t get called if in Browser
			var profile:ProfileData = shellApi.profileManager.active;
			var profileIsland:String = profile.island;
			var curIsland:String = shellApi.island;
			
			if (curIsland) {
				if ((curIsland != "hub") && (curIsland != "clubhouse"))
				{
					profile.previousIsland = curIsland;
				}
			}
			super.shellApi.loadScene((shellApi.sceneManager).gameData.homeClass);
		}
		
		///////////////////////////////////////// SAVE BUTTON /////////////////////////////////////////
		// BROWSER ONLY //
		
		override protected function setupSaveButton( btnClip:MovieClip ):void
		{
			// FOR NOW don't make save button if not guest and not ad interior scene and not ftue intro
			var isFTUEIntro:Boolean = (shellApi.currentScene is Intro);
			if ( (shellApi.profileManager.active.isGuest || isNaN(shellApi.profileManager.active.dbid)) && (!(shellApi.currentScene is AdInteriorScene)) && (!isFTUEIntro) )
			{
				// create save button
				// adjust x position so it aligns with right edge of screen
				btnClip.x = shellApi.viewportWidth -(btnClip.width/2 + BUTTON_OFFSET)
				
				_saveBtn = ButtonCreator.createButtonEntity( btnClip, this, onSaveClick );
				_saveBtn.name = SAVE + BUTTON;
			}
			else
			{
				super.removeClip( btnClip );
			}
		}
		
		private function onSaveClick( btn:Entity ):void
		{
			var trackingManager:TrackingManager = shellApi.getManager(ITrackingManager) as TrackingManager;
			if (trackingManager) {
				trackingManager.trackEvent(SceneUIGroup.UI_EVENT, {cluster:shellApi.island, choice:"Click Save"});
			}
			showRegistrationForm(shellApi.sceneManager.currentScene);
		}
		
		public function showRegistrationForm(group:DisplayGroup):void 
		{
			group.addChildGroup(new SaveGamePopup(shellApi.currentScene.overlayContainer));
		}
		
		public static function buyMembership(shellApi:ShellApi, query:String = null):MembershipPopup 
		{
			if(shellApi.profileManager.active.isGuest)
			{
				var dialogBox:ConfirmationDialogBox = shellApi.currentScene.addChildGroup(new ConfirmationDialogBox(1, "You must save your game first!")) as ConfirmationDialogBox;
				dialogBox.darkenBackground 	= true;
				dialogBox.pauseParent 		= true;
				dialogBox.confirmClicked.addOnce(Command.create(shellApi.currentScene.addChildGroup, new SaveGamePopup(shellApi.currentScene.overlayContainer)))
				dialogBox.init(shellApi.currentScene.overlayContainer);
				return null;
			}
			
			if(!PlatformUtils.isMobileOS)
			{
				var path:String = shellApi.siteProxy.secureHost + "/store/buy-membership.html";
				// if query string and not empty string
				if ((query) && (query != ""))
					path += ("?" + query);
				
				// I think this is a security risk, so we do not pass info along anymore
				/*
				var request:URLRequest = new URLRequest(path);
				var vars:URLVariables = new URLVariables();
				vars.login = shellApi.profileManager.active.login;
				vars.pass_hash = shellApi.profileManager.active.pass_hash;
				request.data = vars;
				request.method = URLRequestMethod.POST;
				*/
				navigateToURL(new URLRequest(path), '_blank');
				return null;
			}
			else
			{
				// ios is the only one stickler enough to require it to go through iap
				return shellApi.currentScene.addChildGroup(new MembershipPopup(shellApi.currentScene.overlayContainer)) as MembershipPopup;
			}
		}		
		
		/////////////////////////////////////// CAMERA ICON ///////////////////////////////////////
		
		/**
		 * BROWSER ONLY - FOR OVERRIDE in browser pop version.
		 */
		override protected function setupPhotoIcon(clip:MovieClip):void
		{
			// setup camera icon
			clip.x -= 80;	// position camera movieclip
			_flashBulbEntity = EntityUtils.createSpatialEntity( this, clip );
			_flashBulbEntity.add(new Sleep(true, true));
			TimelineUtils.convertClip(clip.flashAnim, this, _flashBulbEntity, null, false);
		}
		
		override public function showPhotoNotification( callback:Function = null ):void 
		{
			if( callback != null )	{ photoNotificationCompleted.addOnce(callback); }
			this.slideCameraIn(true);
		}
		
		private function slideCameraIn( slideIn:Boolean=true):void 
		{
			var spatial:Spatial = _flashBulbEntity.get(Spatial);
			if(spatial != null)
			{
				var destX:Number = spatial.x + (slideIn ? 1 : -1) * 80;
				if (slideIn) 
				{ 	
					(_flashBulbEntity.get(Sleep) as Sleep).sleeping = false;
					TweenUtils.entityTo( _flashBulbEntity, Spatial, .25, {x:destX, onComplete:activateStrobeFlash});
				} 
				else 
				{		// slide out
					TweenUtils.entityTo( _flashBulbEntity, Spatial, .25, {x:destX, onComplete:onPhotoNotificationComplete});
				}
			}
		}
		
		public function activateStrobeFlash():void 
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + 'camera_01.mp3');
			var tl:Timeline = _flashBulbEntity.get(Timeline) as Timeline;
			tl.gotoAndPlay("home");
			TimelineUtils.onLabel( _flashBulbEntity, "pop", strobePop );
			TimelineUtils.onLabel( _flashBulbEntity, "maxed", whitenScreen );
		}
		
		private function strobePop():void 
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + 'small_pow_05.mp3');
		}
		
		private function whitenScreen():void 
		{
			var whiteRect:Sprite = new Sprite();
			whiteRect.name = "whiteRect";
			with (whiteRect.graphics) {
				beginFill(0xffffff);
				drawRect(0,0, shellApi.viewportWidth, shellApi.viewportHeight);
			}
			screen.addChild(whiteRect);
			TweenMax.to(whiteRect, 1.125, {alpha:0, onComplete:requestPhotoSpin});
		}
		
		private function rewindFlash():void 
		{
			(_flashBulbEntity.get(Timeline) as Timeline).gotoAndStop('home');
		}
		
		private function requestPhotoSpin():void 
		{
			if(screen != null)
			{
				var whiteRect:DisplayObject = screen.getChildByName("whiteRect");
				if(whiteRect != null)
				{
					screen.removeChild(whiteRect);
				}
			}
			
			slideCameraIn(false);
			
			//(shellApi.sceneManager.currentScene.getGroupById("itemGroup") as ItemGroup).showItem('photo_card', 'common');
		}
		
		private function onPhotoNotificationComplete():void 
		{
			(_flashBulbEntity.get(Sleep) as Sleep).sleeping = true;
			photoNotificationCompleted.dispatch();
		}
	}
}