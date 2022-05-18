package game.ui.settings
{	
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.systems.AudioSystem;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.ui.Button;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.dlc.TransactionRequestData;
	import game.data.sound.SoundModifier;
	import game.managers.LanguageManager;
	import game.managers.ProfileManager;
	import game.scene.template.SceneUIGroup;
	import game.ui.elements.ConfirmationDialogBox;
	import game.ui.elements.ProgressBox;
	import game.ui.hud.Hud;
	import game.ui.popup.Popup;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	import game.util.DisplayPositions;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.TextUtils;
	import game.util.Utils;
	
	/**
	 * Presents a Settings Popup comprising several buttons and text fields.
	 * The chosen values are stored in long term memory for the player.
	 * A confirmation dialog box is presented before changing quality settings.
	 * 
	 * @author Rich Martin, Rick Hocker
	 */
	public class SettingsPopup extends Popup
	{		
		public function SettingsPopup(container:DisplayObjectContainer = null) 
		{
			super(container);
		}
		
		public override function init(container:DisplayObjectContainer = null):void 
		{
			this.groupPrefix 		= "ui/settings/";
			this.screenAsset 		= "settingsPanel.swf";
			this.id = GROUP_ID;
			
			super.init(container);
			this.load();
		}
		
		public override function destroy():void
		{
			// we save current settings when the popup is destroyed
			super.shellApi.setGeneralSettings();		
			super.destroy();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			// position close button at top right
			this.loadCloseButton(DisplayPositions.TOP_RIGHT, 0, 0, false, this.screen);
			
			// center screen
			this.screen.x = this.shellApi.viewportWidth * 0.5 - this.screen.width * 0.5;
			this.screen.y = this.shellApi.viewportHeight * 0.5 - this.screen.height * 0.5;
			
			// get audio system
			this._audioSystem = this.getSystem(AudioSystem) as AudioSystem;
			
			// setup ability to unlock debug
			this.setupDebugModeUnlock();
			
			// update stand-alone text fields
			TextUtils.refreshText(this.screen["settings"]).text = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.settings.settings", "Settings");
			TextUtils.refreshText(this.screen["loggedIn"]).text = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.settings.loggedIn", "Logged in as");
			if (this.shellApi.profileManager.active.avatarFirstName)
				this.screen["avatarName"].text = this.shellApi.profileManager.active.avatarFirstName + " " + this.shellApi.profileManager.active.avatarLastName;
			this.screen["buildInfo"].text = AppConfig.appVersionString;
			
			// update buttons
			this.setupSounds();
			this.setupDialog();
			this.setupQuality();
			this.setupLogOut();
			this.setupRestorePurchases();
			this.setupAccountSettings();
			this.setupHelp();
			this.setupPrivacy();
			this.setupTerms();
		}
		
		///////////////// DEBUG /////////////////
		
		/**
		 * Create four buttons to unlock debugging 
		 */
		private function setupDebugModeUnlock():void
		{
			// if not debugging
			if(!AppConfig.debug)
			{
				// create four debug buttons
				var side:Number = 80;
				var sideHalf:Number = side / 2;
				this.createSquareDebugButton(sideHalf, sideHalf, side, 1);
				this.createSquareDebugButton(this.shellApi.viewportWidth - sideHalf, sideHalf, side, 2);
				this.createSquareDebugButton(this.shellApi.viewportWidth - sideHalf, this.shellApi.viewportHeight - sideHalf, side, 3);
				this.createSquareDebugButton(sideHalf, this.shellApi.viewportHeight - sideHalf, side, 4);
			}
		}
		
		/**
		 * Create debug button 
		 * @param x
		 * @param y
		 * @param side
		 * @param index
		 */
		private function createSquareDebugButton(x:Number, y:Number, side:Number, index:int):void
		{
			// create movie clip
			var sprite:MovieClip = new MovieClip();
			sprite.graphics.beginFill(0x660000, 0);
			sprite.graphics.drawRect(-side/2, -side/2, side, side);
			sprite.graphics.endFill();
			sprite.x = x;
			sprite.y = y;
			
			// add to container
			this.groupContainer.addChild(sprite);
			
			// make into button entity
			var entity:Entity = ButtonCreator.createButtonEntity(sprite, this, onDebugButtonClicked);
			ToolTipCreator.removeFromEntity(entity);
			Button(entity.get(Button)).value = index;
		}
		
		/**
		 * When click on debug button 
		 * @param entity
		 */
		private function onDebugButtonClicked(entity:Entity):void
		{
			// if not debug mode, then check debug index
			if(!AppConfig.debug)
				this.checkDebugIndex(Button(entity.get(Button)).value);
		}
		
		/**
		 * Check index for clicked debug button 
		 * @param index
		 */
		private function checkDebugIndex(index:int):void
		{
			trace("SettingsPopup :: Debug Unlock Step =", index, "/ 4");
			
			// if index follows unlock sequence
			if(index == this.debugUnlockCombo[this.debugUnlockIndex])
			{
				// incremement index
				++this.debugUnlockIndex;
				// if complete sequence
				if(this.debugUnlockIndex == this.debugUnlockCombo.length)
				{
					// reset index and set debug mode
					this.debugUnlockIndex = 0;
					AppConfig.debug = true;
					trace("SettingsPopup :: Debug Mode Unlocked");
					this.shellApi.triggerEvent("debug_mode_unlocked");
				}
			}
			else
			{
				// if messed up sequence
				// reset index
				this.debugUnlockIndex = 0;
				// if you screwed up the sequence, but you clicked the first one, then let's start over at the first one.
				if(index == 1)
					this.checkDebugIndex(index);
			}
		}
		
		///////////////// SETUP /////////////////
		
		/**
		 * Setup music and sound effects buttons 
		 */
		private function setupSounds():void
		{
			// refresh text
			TextUtils.refreshText(this.screen["sounds"]).text = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.settings.sounds", "Sounds");
			TextUtils.refreshText(this.screen["music"]).text = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.settings.music", "Music");
			TextUtils.refreshText(this.screen["effects"]).text = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.settings.effects", "Effects");
			
			// setup music buttons
			this._musicOnButton = ButtonCreator.createButtonEntity(this.screen["musicOn"], this, Command.create(this.onMusicClicked, false));
			this._musicOffButton = ButtonCreator.createButtonEntity(this.screen["musicOff"], this, Command.create(this.onMusicClicked, true));
			
			// get curremt volume and hide/show buttons
			var volume:Number = this._audioSystem.getVolume(SoundModifier.MUSIC);
			if (volume == 0)
				this._musicOnButton.get(Display).visible = false;
			else
				this._musicOffButton.get(Display).visible = false;
			
			// setup sound effects buttons
			this._sfxOnButton = ButtonCreator.createButtonEntity(this.screen["soundfxOn"], this, Command.create(this.onEffectsClicked, false));
			this._sfxOffButton = ButtonCreator.createButtonEntity(this.screen["soundfxOff"], this, Command.create(this.onEffectsClicked, true));
			
			// get curremt volume and hide/show buttons
			volume = this._audioSystem.getVolume(SoundModifier.EFFECTS);
			if (volume == 0)
				this._sfxOnButton.get(Display).visible = false;
			else
				this._sfxOffButton.get(Display).visible = false;
		}
		
		/**
		 * Setup dialog speed buttons 
		 */
		private function setupDialog():void
		{
			// refresh text
			TextUtils.refreshText(this.screen["dialog"]).text = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.settings.dialog", "Dialog Speed");
			TextUtils.refreshText(this.screen["slow"]).text = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.settings.slow", "Slow");
			TextUtils.refreshText(this.screen["medium"]).text = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.settings.medium", "Medium");
			TextUtils.refreshText(this.screen["fast"]).text = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.settings.fast", "Fast");
			
			// setup buttons
			this._dialogSlowButton = ButtonCreator.createButtonEntity(this.screen["dialogSlow"], this, Command.create(this.onDialogClicked, "slow"));
			this._dialogMedButton = ButtonCreator.createButtonEntity(this.screen["dialogMed"], this, Command.create(this.onDialogClicked, "med"));
			this._dialogFastButton = ButtonCreator.createButtonEntity(this.screen["dialogFast"], this, Command.create(this.onDialogClicked, "fast"));
			
			// get dialog speed
			var dialogSpeed:Number = shellApi.profileManager.active.dialogSpeed;
			if (isNaN(dialogSpeed)) 
				dialogSpeed = Dialog.DEFAULT_DIALOG_SPEED;
			
			// convert to within 0-1 range
			var decimal:Number = Utils.toDecimal(dialogSpeed, Dialog.MIN_DIALOG_SPEED, Dialog.MAX_DIALOG_SPEED);
			
			// show hilite based on decimal value
			_dialogHilite = this.screen["dialogHilite"];
			_dialogHilite.mouseEnabled = false;
			if (decimal <= 0.33)
				_dialogHilite.x = this._dialogFastButton.get(Spatial).x;
			else if (decimal <= 0.66)
				_dialogHilite.x = this._dialogMedButton.get(Spatial).x;
			else
				_dialogHilite.x = this._dialogSlowButton.get(Spatial).x;
		}
		
		/**
		 * Setup quality settings buttons 
		 */
		private function setupQuality():void
		{
			// refresh text
			TextUtils.refreshText(this.screen["quality"]).text = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.settings.quality", "Graphics Quality");
			TextUtils.refreshText(this.screen["lowq"]).text = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.settings.lowq", "Low");
			TextUtils.refreshText(this.screen["mediumq"]).text = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.settings.mediumq", "Medium");
			TextUtils.refreshText(this.screen["highq"]).text = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.settings.highq", "High");
			
			// setup buttons
			this._qualityLowButton = ButtonCreator.createButtonEntity(this.screen["qualityLow"], this, Command.create(this.onQualityClicked, "low"));
			this._qualityMedButton = ButtonCreator.createButtonEntity(this.screen["qualityMed"], this, Command.create(this.onQualityClicked, "med"));
			this._qualityHighButton = ButtonCreator.createButtonEntity(this.screen["qualityHigh"], this, Command.create(this.onQualityClicked, "high"));
			
			// get quality level
			var qualityLevel:Number = shellApi.profileManager.active.qualityOverride;
			if ( isNaN(qualityLevel) || qualityLevel < 0 )
				qualityLevel = PerformanceUtils.qualityLevel;
			
			// convert to within 0-1 range
			var decimal:Number = Utils.toDecimal(qualityLevel, AppConfig.minimumQuality, PerformanceUtils.QUALITY_HIGHEST);
			
			// show hilite based on decimal value
			_qualityHilite = this.screen["qualityHilite"];
			_qualityHilite.mouseEnabled = false;
			if (decimal <= 0.33)
				_qualityHilite.x = this._qualityLowButton.get(Spatial).x;
			else if (decimal <= 0.66)
				_qualityHilite.x = this._qualityMedButton.get(Spatial).x;
			else
				_qualityHilite.x = this._qualityHighButton.get(Spatial).x;	
		}
		
		/**
		 * Setup logout button for mobile 
		 */
		private function setupLogOut():void
		{
			// if not mobile, then remove button
			if(!PlatformUtils.isMobileOS)
			{
				//this.screen.removeChild(this.screen["logOutButton"]);
				//return;
			}
			
			// create button
			_logoutButton = ButtonCreator.createButtonEntity(this.screen["logOutButton"], this, this.onLogOutClicked);
			
			// apply text
			var text:String = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.settings.logOut", "Log Out");
			ButtonCreator.addLabel(this.screen["logOutButton"], text, new TextFormat("CreativeBlock BB", 17, 0xFFFFFF), ButtonCreator.ORIENT_CENTERED);
		}
		
		/**
		 * Setup restore purchases button for mobile
		 */
		private function setupRestorePurchases():void
		{
			trace("mobile: " + PlatformUtils.isMobileOS + " iap on: " + AppConfig.iapOn);
			
			var clip:MovieClip = this.screen["restorePurchasesButton"];
			// if not mobile or IAP is turned off. then remove button
			if(!PlatformUtils.isMobileOS || !AppConfig.iapOn)
			{
				this.screen.removeChild(clip);
				return;
			}
			if(isNaN(shellApi.profileManager.active.dbid))// if no account settings replace it
			{
				clip.y = this.screen["accountSettingsButton"].y;
			}
			// create button
			_restoreButton = ButtonCreator.createButtonEntity(clip, this, this.onRestorePurchasesClicked);
			
			// apply text
			var text:String = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.settings.restorePurchases", "Restore Purchases");
			ButtonCreator.addLabel(clip, text, new TextFormat("CreativeBlock BB", 17, 0xFFFFFF), ButtonCreator.ORIENT_CENTERED);
		}
		
		/**
		 * Setup account settings button for web 
		 */
		private function setupAccountSettings():void
		{
			// if mobile then turn off
			if(PlatformUtils.isMobileOS && isNaN(shellApi.profileManager.active.dbid))
			{
				this.screen.removeChild(this.screen["accountSettingsButton"]);
				return;
			}
			
			// create button
			_accountButton = ButtonCreator.createButtonEntity(this.screen["accountSettingsButton"], this, this.onAccountSettingsClicked);
			
			// apply text
			var text:String = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.settings.accountSettings", "Account Settings");
			ButtonCreator.addLabel(this.screen["accountSettingsButton"], text, new TextFormat("CreativeBlock BB", 17, 0xFFFFFF), ButtonCreator.ORIENT_CENTERED);
		}
		
		/**
		 * Setup help and support button 
		 */
		private function setupHelp():void
		{
			// create button
			_helpButton = ButtonCreator.createButtonEntity(this.screen["helpButton"], this, this.onHelpClicked);
			
			// apply text
			var text:String = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.settings.help", "Help & Support");
			ButtonCreator.addLabel(this.screen["helpButton"], text, new TextFormat("CreativeBlock BB", 17, 0xFFFFFF), ButtonCreator.ORIENT_CENTERED);
		}
		/**
		 * Setup privacy button 
		 */
		private function setupPrivacy():void
		{
			// create button
			_privacyButton = ButtonCreator.createButtonEntity(this.screen["privacyButton"], this, this.onPrivacyClicked);
			
			// apply text
			var text:String = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.settings.privacy", "Privacy Policy");
			ButtonCreator.addLabel(this.screen["privacyButton"], text, new TextFormat("CreativeBlock BB", 17, 0xFFFFFF), ButtonCreator.ORIENT_CENTERED);
		}
		/**
		 * Setup terms button 
		 */
		private function setupTerms():void
		{
			// create button
			_termsButton = ButtonCreator.createButtonEntity(this.screen["termsButton"], this, this.onTermsClicked);
			
			// apply text
			var text:String = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.settings.terms", "Terms of Use");
			ButtonCreator.addLabel(this.screen["termsButton"], text, new TextFormat("CreativeBlock BB", 17, 0xFFFFFF), ButtonCreator.ORIENT_CENTERED);
		}
		///////////////// BUTTON HANDLERS /////////////////
		
		/**
		 * When music buttons clicked 
		 * @param entity
		 * @param state
		 */
		private function onMusicClicked(entity:Entity, state:Boolean):void
		{
			this.playClick();
			
			var volume:Number;
			// if turning on music
			if (state)
			{
				volume = ProfileManager.DEFAULT_MUSIC_VOLUME;
				// toggle buttons
				_musicOnButton.get(Display).visible = true;
				_musicOffButton.get(Display).visible = false;
			}
			else
			{
				volume = 0;
				// toggle buttons
				_musicOnButton.get(Display).visible = false;
				_musicOffButton.get(Display).visible = true;
			}
			
			// set new volume
			this._audioSystem.setVolume(volume, SoundModifier.MUSIC);
			this._audioSystem.setVolume(volume, SoundModifier.AMBIENT);
			this.shellApi.profileManager.active.musicVolume = volume;
			this.shellApi.profileManager.active.ambientVolume = volume;
		}
		
		/**
		 * When sound effects buttons clicked 
		 * @param entity
		 * @param state
		 */
		private function onEffectsClicked(entity:Entity, state:Boolean):void
		{
			this.playClick();
			
			var volume:Number;
			// if turning on sfx
			if (state)
			{
				volume = ProfileManager.DEFAULT_SFX_VOLUME;
				// toggle buttons
				_sfxOnButton.get(Display).visible = true;
				_sfxOffButton.get(Display).visible = false;
			}
			else
			{
				volume = 0;
				// toggle buttons
				_sfxOnButton.get(Display).visible = false;
				_sfxOffButton.get(Display).visible = true;
			}
			
			// set new volume
			this._audioSystem.setVolume(volume, SoundModifier.EFFECTS);
			this.shellApi.profileManager.active.effectsVolume = volume;
		}
		
		/**
		 * When dialog speed buttons clicked 
		 * @param entity
		 * @param speed
		 */
		private function onDialogClicked(entity:Entity, speed:String):void
		{
			this.playClick();
			
			var dialogSpeed:Number;
			var decimal:Number;
			// update based on speed string
			switch (speed)
			{
				case "slow": // longest time for dialog
					decimal = 1;
					dialogSpeed = Dialog.MAX_DIALOG_SPEED;
					_dialogHilite.x = this._dialogSlowButton.get(Spatial).x;
					break;
				case "med":
					decimal = 0.5;
					// get halfway point
					dialogSpeed = Utils.fromDecimal(decimal, Dialog.MIN_DIALOG_SPEED, Dialog.MAX_DIALOG_SPEED);
					_dialogHilite.x = this._dialogMedButton.get(Spatial).x;
					break;
				case "fast": // shortest time for dialog
					decimal = 0;
					dialogSpeed = Dialog.MIN_DIALOG_SPEED;
					_dialogHilite.x = this._dialogFastButton.get(Spatial).x;
					break;
			}
			
			// set dialog speed if changed
			if (this.shellApi.profileManager.active.dialogSpeed != dialogSpeed)
			{
				this.shellApi.profileManager.active.dialogSpeed = dialogSpeed;
				this.shellApi.track(DIALOG_SPEED_CHANGED, decimal, null, SceneUIGroup.UI_EVENT);
			}
		}
		
		/**
		 * When logout button clicked 
		 * @param entity
		 */
		private function onLogOutClicked(entity:Entity):void
		{
			this.playClick();
			
			// show dialog (clicking okay will return user to start screen)
			var message:String = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.settings.logOutText", "Are you sure you want to log out?");
			var startScreenClass:Class = ClassUtils.getClassByName('game.scenes.start.login.Login');
			var box:ConfirmationDialogBox = new ConfirmationDialogBox(1, String( "\r" + message), Command.create(this.shellApi.loadScene, startScreenClass), null, true, true);
			box.pauseParent = true;
			this.addChildGroup(box);
			box.init(this.groupContainer);
		}
		
		/**
		 * When help and support button clicked 
		 * @param entity
		 */
		private function onHelpClicked(entity:Entity):void
		{
			this.playClick();
			
			// help page
			var clickURL:String = this.shellApi.siteProxy.secureHost + "/Poptropica-FAQ.html?source=POP_text_Help_HomeNavTop-pop&medium=Text&campaign=POPHelp";
			
			// open help page in new window
			navigateToURL(new URLRequest(clickURL), "_blank");
		}
		/**
		 * When privacy button clicked 
		 * @param entity
		 */
		private function onPrivacyClicked(entity:Entity):void
		{
			this.playClick();
			
			// help page
			var clickURL:String = this.shellApi.siteProxy.secureHost + "/privacy/";
			
			// open help page in new window
			navigateToURL(new URLRequest(clickURL), "_blank");
		}
		/**
		 * When terms button clicked 
		 * @param entity
		 */
		private function onTermsClicked(entity:Entity):void
		{
			this.playClick();
			
			// help page
			var clickURL:String = this.shellApi.siteProxy.secureHost + "/about/terms-of-use.html";
			
			// open help page in new window
			navigateToURL(new URLRequest(clickURL), "_blank");
		}
		/**
		 * When clicking the account settings button 
		 * @param entity
		 */
		private function onAccountSettingsClicked(entity:Entity):void
		{
			this.playClick();
			
			// close this popup
			this.close();
			
			// show account settings popup
			var accountSettings:Popup = new AccountSettingsPopup();
			var hud:Hud = Hud(super.getGroupById(Hud.GROUP_ID));
			accountSettings.popupRemoved.addOnce( hud.closeSettings );
			hud.addChildGroup(accountSettings);
			accountSettings.init( hud.groupContainer);
			hud.enableHUDButtons(false, true);
		}
		
		///////////////// QUALITY SETTINGS /////////////////
		
		/**
		 * When quality settings buttons clicked 
		 * @param entity
		 * @param quality
		 */
		private function onQualityClicked(entity:Entity, quality:String):void
		{
			this.playClick();
			
			// update based on quality string
			switch (quality)
			{
				case "low":
					_newQuality = AppConfig.minimumQuality;
					_qualityHilite.x = this._dialogSlowButton.get(Spatial).x;
					break;
				case "med":
					// get halfway point
					_newQuality = Utils.fromDecimal(0.5, AppConfig.minimumQuality, PerformanceUtils.QUALITY_HIGHEST);
					// round to nearest 10
					_newQuality = Math.round(_newQuality / 10) * 10;
					_qualityHilite.x = this._dialogMedButton.get(Spatial).x;
					break;
				case "high":
					_newQuality = PerformanceUtils.QUALITY_HIGHEST;
					_qualityHilite.x = this._dialogFastButton.get(Spatial).x;
					break;
			}
			
			// if quality has changed, then shwo dialog (clicking okay will save the quality change)
			if(_newQuality != PerformanceUtils.qualityLevel)
			{
				var defaultText:String = "Are you sure you'd like to change your graphics quality?  This will require the current scene to reload.";
				var message:String = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.settings.changeGraphicsQualityText", defaultText);
				var box:ConfirmationDialogBox = new ConfirmationDialogBox(2, message, saveQualityChange, cancelQualityChange, false, true);
				box.pauseParent = true;
				this.addChildGroup(box);
				box.init(this.groupContainer);
			}
		}
		
		/**
		 * Save quality setting when clicking okay on popup
		 */
		private function saveQualityChange():void
		{
			// NOTE: On certain applications we may want to vary the minimum the quality, one example is browser
			
			// set new quality
			PerformanceUtils.qualityLevel = _newQuality;			
			PerformanceUtils.determineAndSetVectorQuality();
			PerformanceUtils.determineAndSetDefaultBitmapQuality();
			
			// save quality
			super.shellApi.profileManager.active.qualityOverride = _newQuality;
			super.shellApi.profileManager.save();
			super.shellApi.track(GRAPHICS_QUALITY_CHANGED, _newQuality, null, SceneUIGroup.UI_EVENT);
			
			// reload current scene
			var spatial:Spatial = this.shellApi.player.get(Spatial);
			var direction:String = spatial.scaleX > 0 ? CharUtils.DIRECTION_LEFT : CharUtils.DIRECTION_RIGHT;		
			var sceneClass:Class = ClassUtils.getClassByObject(this.shellApi.currentScene);
			this.shellApi.loadScene(sceneClass, spatial.x, spatial.y, direction);
		}
		
		/**
		 * Resets quality hilite to previous when clicking cancel on popup
		 */
		private function cancelQualityChange():void
		{
			// convert convert quality to within 0-1 range
			var decimal:Number  = Utils.toDecimal(PerformanceUtils.qualityLevel, AppConfig.minimumQuality, PerformanceUtils.QUALITY_HIGHEST);
			
			// move hilite to current setting
			if (decimal <= 0.33)
				_qualityHilite.x = this._qualityLowButton.get(Spatial).x;
			else if (decimal <= 0.66)
				_qualityHilite.x = this._qualityMedButton.get(Spatial).x;
			else
				_qualityHilite.x = this._qualityHighButton.get(Spatial).x;			
		}
		
		///////////////// RESTORE PURCHASES /////////////////
		
		/**
		 * 
		 * When click on restore purchases button 
		 * @param entity
		 */
		private function onRestorePurchasesClicked(entity:Entity):void
		{
			this.playClick();
			
			var progressBox:ProgressBox;
			var defaultText:String;
			var message:String;
			var title:String = "Purchase Restore";
			
			// if network
			if(shellApi.networkAvailable())
			{
				// create wait dialog
				defaultText = "Please wait while your purchases restore...";
				message = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.settings.waitRestore", defaultText);
				createRestoreDialogBox( ProgressBox.STATE_WAITING, title, message);
				
				// restore purchases
				shellApi.dlcManager.restoreAllPurchases(restoreComplete, restoreFailure);
				//SceneUtil.delay( progressBox, 3, restoreComplete );	// FOR TESTING	
			}
			else
			{
				// if not network
				// create dialog telling user to connect
				defaultText = "You must be connected to the internet to restore purchases.";
				message = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.settings.connectRestore", defaultText);
				createRestoreDialogBox( ProgressBox.STATE_NONE, title, message);
			}
		}
		
		/**
		 * Create restoring purchase dialog box 
		 * @param state
		 * @param title
		 * @param message
		 */
		private function createRestoreDialogBox(state:String, title:String, message:String):void
		{
			var progressBox:ProgressBox = new ProgressBox( this.groupContainer );
			progressBox.setup( state, title, message, true, true);
			progressBox.id = RESTORE_PURCHASE_ID;
			this.addChildGroup(progressBox);
		}
		
		/**
		 * When restoring is complete 
		 * @param request
		 */
		public function restoreComplete(request:TransactionRequestData) : void
		{
			trace(this,"restoreComplete",request.message);
			
			// show progress box with message
			var progressBox:ProgressBox = super.getGroupById(RESTORE_PURCHASE_ID) as ProgressBox;
			progressBox.message = request.message;
			//progressBox.statusText = "Purchases have been restored.";	// FOR TESTING
			progressBox.setState( ProgressBox.STATE_NONE, true );
		}
		
		/**
		 * When restoring fails 
		 * @param request
		 */
		public function restoreFailure(request:TransactionRequestData) : void
		{
			trace(this,"restoreFailure",request.message);
			
			// show progress box with message
			var progressBox:ProgressBox = super.getGroupById(RESTORE_PURCHASE_ID) as ProgressBox;
			progressBox.message = request.message;
			//progressBox.statusText = "Purchases have been restored.";	// FOR TESTING
			progressBox.setState( ProgressBox.STATE_NONE, true );
		}
		
		// IDs
		public static const GROUP_ID:String = "settings_panel";
		private static const RESTORE_PURCHASE_ID:String = "restore_purchase"
		
		// brain tracking events
		private static const DIALOG_SPEED_CHANGED:String = 'DialogSpeedChanged';
		private static const GRAPHICS_QUALITY_CHANGED:String = "GraphicsQualityChanged";
		
		// debug vars
		private var debugUnlockCombo:Array = [1, 2, 3, 4];
		private var debugUnlockIndex:int = 0;
		
		// buttons and button hilites
		private var _musicOnButton:Entity;
		private var _musicOffButton:Entity;
		private var _sfxOnButton:Entity;
		private var _sfxOffButton:Entity;
		private var _dialogSlowButton:Entity;
		private var _dialogMedButton:Entity;
		private var _dialogFastButton:Entity;
		private var _qualityLowButton:Entity;
		private var _qualityMedButton:Entity;
		private var _qualityHighButton:Entity;
		private var _dialogHilite:MovieClip;
		private var _qualityHilite:MovieClip;
		private var _logoutButton:Entity;
		private var _restoreButton:Entity;
		private var _accountButton:Entity;
		private var _helpButton:Entity;
		private var _termsButton:Entity;
		private var _privacyButton:Entity;
		
		private var _audioSystem:AudioSystem;
		private var _newQuality:int;
	}
}