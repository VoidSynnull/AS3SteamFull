package game.scenes.start.login
{
	import com.poptropica.AppConfig;
	import com.poptropica.shells.browser.steps.BrowserStepGetStoreCards;
	import com.poptropica.shells.mobile.steps.MobileStepGetStoreCards;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	import engine.systems.RenderSystem;
	import engine.systems.TweenSystem;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.data.animation.entity.character.Pop;
	import game.data.character.LookAspectData;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.comm.PopResponse;
	import game.data.profile.MembershipStatus;
	import game.data.profile.ProfileData;
	import game.data.sound.SoundModifier;
	import game.data.ui.ToolTipType;
	import game.proxy.DataStoreRequest;
	import game.scene.template.CharacterGroup;
	import game.scene.template.GameScene;
	import game.scenes.hub.town.Town;
	import game.scenes.map.map.Map;
	import game.scenes.start.login.components.ContextButton;
	import game.scenes.start.login.data.CharLookLibrary;
	import game.scenes.start.login.groups.BackgroundAnimationsGroup;
	import game.scenes.start.login.groups.CharacterCreation;
	import game.scenes.start.login.groups.FillOutLoginProfile;
	import game.scenes.start.login.popups.WarningPopup;
	import game.scenes.start.startScreen.components.AgeDial;
	import game.scenes.start.startScreen.groups.DialGroup;
	import game.scenes.start.startScreen.groups.ProfileGroup;
	import game.systems.entity.EyeSystem;
	import game.systems.input.InteractionSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.systems.timeline.TimelineRigSystem;
	import game.systems.ui.ButtonSystem;
	import game.ui.elements.ConfirmationDialogBox;
	import game.ui.login.LoginResult;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.InputFieldUtil;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	import game.util.Utils;
	
	
	public class Login extends Scene
	{
		private var doMapABTest:Boolean = false;   //this is for 25 to map 75 to home
		private var screen:MovieClip;
		private var content:MovieClip;
		//key groups
		private var profileGroup:ProfileGroup;
		private var characterGroup:CharacterGroup;
		private var creationGroup:CharacterCreation;
		private var loginProfile:FillOutLoginProfile;
		private var backgroundTheme:BackgroundAnimationsGroup;
		// key states
		private var state:int = 0;//actual state
		private const RETURN_USER:int = -2;
		private const PARENT_EMAIL:int = -1;
		private const INIT:int = 0;
		private const AGE_GENDER:int = int.MAX_VALUE;//removing this section
		private const CHARCER_CREATION:int = 1;
		private const NAME_GENERATION:int = 2;
		
		private const STATE_NAMES:Array = ["ParentEmail","Login","Avatar","Name"];
		
		private const PARENT_EMAIL_REMINDER_RATE:int = 3;
		private const MAX_PROFILES:int = 7;
		
		// context actions
		private const NEXT:String = "next";
		private const BACK:String = "back";
		private const PLAY:String = "play";
		private const RTRN:String = "returnUser";
		// main colors for buttons
		private const GREEN:Number =  0x8DD600;
		private const ORANGE:Number = 0xED9500;
		private const PURPLE:Number = 0x5C3FDB;
		private const MAROON:Number = 0xB43FDB;
		private const FORGOT:Number = 0xD84467;
		private const FONT:String	= "Billy Bold";
		private const NUM_SIZE:Number = 48;
		private const TEXT_SIZE:Number = 24;
		// key buttons
		private var next:Entity;
		private var back:Entity;
		private var returnUser:Entity;
		private var create:Entity;
		private var login:Entity;
		private var later:Entity;
		private var submit:Entity;
		private var forgotPassword:Entity;
		// key set pieces
		private var island:Entity;
		private var loginScreen:Entity;
		private var nameDial:Entity;
		private var ageDial:Entity;
		private var genderSelect:Entity;
		private var characterCreation:Entity;
		private var emailReminder:Entity;
		private var pole:Timeline;
		private var backToLogin:Entity;
		private var startNewPlayer:Entity;
		// login fields
		private var userName:TextField;
		private var password:TextField;
		private var pass_vail:TextField;
		private var email:TextField;
		private var reminderMessage:TextField;
		private var emailError:TextField;
		private var nameDisplay:TextField;
		// avatar key info
		private var age:int = 12;
		private var firstName:String;
		private var lastName:String;
		private var gender:String;
		//choices
		private var genders:Array = [SkinUtils.GENDER_MALE ,SkinUtils.GENDER_FEMALE];
		private var first_names:Array = ["billy","silly","gilly"];
		private var last_names:Array = ["bob","dan","joe","george","jones","drew","guy"];
		private var boyLooks:CharLookLibrary;
		private var girlLooks:CharLookLibrary;
		private var allLooks:CharLookLibrary;
		private var neutralLooks:CharLookLibrary;
		private var ages:Array = [6,7,8,9,10,11,12,13,14,"15+"];
		private var firstNames:AgeDial;
		private var lastNames:AgeDial;
		private var agesDial:AgeDial;
		
		private var dummy:Entity;
		private var startLook:LookData;
		private var customLook:LookData;
		
		private var targetTF:TextField;
		
		private var supressInitAge:Boolean = true;
		private var supressInitFirstName:Boolean = true;
		private var supressInitLastName:Boolean = true;
		
		private var keyInfo:Object;
		private var requestedLogin:Boolean = false;
		private var overwriteProfile:Boolean = false;
		
		private var fullyLoaded:Boolean = false;
		
		private var testChanges:Boolean = false;
		private var testPercent:Number = 1;//0-1
		private var startNewChar:Boolean = false;
		
		private var profiles:int;
		
		public function Login()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			shellApi.profileManager.create(shellApi.profileManager.defaultProfileId, true);
			shellApi.itemManager.reset(null,false);
			shellApi.gameEventManager.reset(null, false);
			PerformanceUtils.qualityLevel = PerformanceUtils.determineQualityLevel();
			var soundManager:SoundManager = shellApi.getManager(SoundManager) as SoundManager;
			soundManager.muteMixer(false);
			shellApi.ShellBase.resetPostBuildProcess();
			super.groupPrefix = "scenes/start/login/";
			
			super.init(container);
			
			super.loadFiles([GameScene.SOUNDS_FILE_NAME, "login.swf"], false, true, this.loaded);
		}
		// all assets ready
		override public function loaded():void
		{
			screen = this.getAsset("login.swf", true);
			this.groupContainer.addChild(screen);
			content = screen["content"];
			
			var bg:MovieClip = screen["bgBack"]["sky"];
			trace("Login :: viewport: " + shellApi.viewportWidth);
			bg.width = shellApi.viewportWidth;
			bg.height = shellApi.viewportHeight;
			content.x = screen["npcPlatform"].x = shellApi.viewportWidth/2;
			content.y = screen["npcPlatform"].y = shellApi.viewportHeight/2;
			
			addSystems();
			setUpContextButtons();
			setUpSetPieces();
			setUpGenderButtons();
			setUpLogin();
			setUpEmailReminder();
			pole = TimelineUtils.convertClip(screen["npcPlatform"]["island"]["platform"]["pole"],this,null,null,false).get(Timeline);
			
			TimelineUtils.convertAllClips(screen["bgBack"],null, this);
			TimelineUtils.convertAllClips(screen["bgFront"], null, this);
			TimelineUtils.convertClip(screen["fg"]);
			
			//adjusting buttons for verbage vs shorthand functionality
			ContextButton(create.get(ContextButton)).Update("NEW PLAYER", -1, NEXT);
			
			// determine if should show return user button
			profiles = 0;
			var firstTime:Boolean = true;
			var validQuerry:Boolean = false;
			var queryString:String;
			if(true)
			{
				testChanges = false;
				for each (var profileData:ProfileData in shellApi.profileManager.profiles)
				{
					trace(profileData.toString());
					if(profileData.login == "default1" && profileData.avatarName == "hamburger hamburger" && isNaN(profileData.lastX))
						continue;
					profiles++;
				}
			}
			else
			{
				if (PlatformUtils.inBrowser)
				{
					testChanges = !shellApi.cmg_iframe;
					/*
					queryString = String(ExternalInterface.call("function() { return window.location.search; }"));
					validQuerry = queryString.indexOf("clicked=") != -1;
					if(validQuerry)
					{
						var charLSO:SharedObject = SharedObject.getLocal("loginFormat");
						charLSO.objectEncoding = ObjectEncoding.AMF0;
						firstTime = charLSO.data.loginFormat == null;
						var val:Number = firstTime?Math.random():charLSO.data.loginFormat
						charLSO.data.loginFormat = val;
						charLSO.flush();// uncomment after testing is complete
						testChanges = val < testPercent;
					}
					*/
				}
			}
			
			if(testChanges)
			{
				if(firstTime)
					shellApi.track("ABTest_choice", "split", "", "ABTest_LoginFlow");
				else
					shellApi.track("ABTest_chosen", "split", "", "ABTest_LoginFlow");
				
				startNewChar = true;
				// handle web a little different
				var clip:MovieClip = content["backToLogin"];
				backToLogin = ButtonCreator.createButtonEntity(clip, this, backToLoginClicked);
				clip = content["loginScreen"]["startNewPlayer"];
				startNewPlayer = ButtonCreator.createButtonEntity(clip, this, startNewPlayerClicked);
			}
			else
			{
				if(validQuerry)
				{
					if(firstTime)
						shellApi.track("ABTest_choice", "combined", "", "ABTest_LoginFlow");
					else
						shellApi.track("ABTest_chosen", "combined", "", "ABTest_LoginFlow");
				}
				
				content.removeChild(content["backToLogin"]);
				content["loginScreen"].removeChild(content["loginScreen"]["startNewPlayer"]);
			}
			
			if(profiles > 1)
			{
				var context:ContextButton = returnUser.get(ContextButton);
				var format:TextFormat = context.TF.defaultTextFormat;
				format.size = 24;
				context.TF.setTextFormat(format);
				context.TF.defaultTextFormat = format;
			}
			else
			{
				removeEntity(returnUser);
				returnUser = null;
			}
			getNpcLooksFromCMS();
			// get background animations
			// these are not required, so 
			// i think it is safe to have 
			// them loaded on their own 
			getBackgroundThemeFromCMS();
			
			//privacy policy
			clip = content["privacyPolicy"];
			var privacyPolicy:Entity = ButtonCreator.createButtonEntity(clip, this, linkToPrivacyPolicy,null,new Array(InteractionCreator.CLICK),ToolTipType.CLICK);
			super.shellApi.screenManager.setSize();
		}
		
		private function startNewPlayerClicked(entity:Entity):void
		{
			customizeTracking("NeedNewUser");
			//track create new character clicked
			changeState(NEXT);
		}
		private function linkToPrivacyPolicy(entity:Entity):void
		{
			navigateToURL(new URLRequest('https://www.poptropica.com/privacy/'), '_blank');
		}
		private function backToLoginClicked(entity:Entity):void
		{
			//track back to login clicked
			customizeTracking("BackToLogin");
			if(PlatformUtils.inBrowser && !shellApi.devTools.console.devLoginEnabled)
			{
				navigateToURL(new URLRequest('/login-page.html'), '_self');
			}
			else
			{
				state = INIT;
				prepareState(BACK);
			}
		}
		
		private function setUpEmailReminder():void
		{
			reminderMessage = TextUtils.refreshText(content["emailReminder"]["message"], FONT);
			email = TextUtils.refreshText(content["emailReminder"]["email"],FONT);
			email.addEventListener(KeyboardEvent.KEY_DOWN, checkPressedEnter);
			emailError = TextUtils.refreshText(content["emailReminder"]["errorMessage"], FONT);
			ContextButton(submit.get(ContextButton)).Update("SUBMIT", -1, PLAY);
			ContextButton(later.get(ContextButton)).Update("MAYBE LATER", -1, BACK);
		}
		
		private function getBackgroundThemeFromCMS():void
		{
			//getBackgrounds("default");
			//return;
			var postVars:URLVariables = new URLVariables();
			
			var url:String = super.shellApi.siteProxy.secureHost + "/get_reg_animations.php";
			var req:URLRequest = new URLRequest(url);
			req.method = URLRequestMethod.GET;
			req.data = postVars;
			
			var loader:URLLoader = new URLLoader(req);
			loader.addEventListener(Event.COMPLETE,retrievedBackgrounds);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onGetBackgroundsError);
			loader.load(req);
		}
		
		private function retrievedBackgrounds(event:Event = null):void
		{
			removeListeners(event, retrievedBackgrounds, onGetBackgroundsError);
			var theme:String
			if(event && event.target.data != null)
			{
				theme = event.target.data;
			}
			else
			{
				theme = "default";
			}
			
			getBackgrounds(theme);
			
		}
		
		private function onGetBackgroundsError(event:IOErrorEvent):void
		{
			shellApi.logWWW(event.errorID, event.text);
			retrievedBackgrounds();
		}
		
		private function getBackgrounds(theme:String):void
		{
			var url:String = groupPrefix+"animations/"+theme+".xml";
			backgroundTheme = addChildGroup(new BackgroundAnimationsGroup(screen["bgAnimationContainer"])) as BackgroundAnimationsGroup;
			backgroundTheme.config(url);
			backgroundTheme.animsLoaded.addOnce(createAnimation);
		}
		
		private function createAnimation():void
		{
			backgroundTheme.createRandomAnimation(createAnimation);
		}
		
		private function getNpcLooksFromCMS(...args):void
		{
			var postVars:URLVariables = new URLVariables();
			
			var url:String = super.shellApi.siteProxy.secureHost + "/npcs.php";
			var req:URLRequest = new URLRequest(url);
			req.method = URLRequestMethod.GET;
			req.data = postVars;
			
			var loader:URLLoader = new URLLoader(req);
			loader.addEventListener(Event.COMPLETE,getNpcLooks);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onGetNpcLooksError);
			loader.load(req);
		}
		
		protected function onGetNpcLooksError(event:IOErrorEvent):void
		{
			shellApi.logWWW(event.errorID, event.text);
			getNpcLooks(null);
		}
		
		private function getNpcLooks(event:Event = null):void
		{
			removeListeners(event, getNpcLooks, onGetNpcLooksError);
			var lookConverter:LookConverter = new LookConverter();
			var lookString:String;
			if(event && event.target.data != null)
			{
				var data:Object = JSON.parse(event.target.data);
				lookString = data["newPlayerButton"].look;
				startLook = lookConverter.lookDataFromLookString(lookString);
				lookString = "1,0xdecc08f,0x543525,12360050,79,3,1,char15,4,char29,char11,1,1,1,1,1,1";
				customLook = lookConverter.lookDataFromLookString(lookString);
				getNames();
			}
			else
			{
				super.loaded();
				
				openWarningPopup("could not connect to servers check connection and try again", getNpcLooksFromCMS);
			}
		}
		
		private function setUpLogin():void
		{
			userName = TextUtils.refreshText(content["loginScreen"]["username"], FONT);
			//font where password settings actually work
			if(PlatformUtils.isIOS)
			{
				password = TextUtils.refreshText(content["loginScreen"]["password"], "Arial");
			}
			else
			{
				password = TextUtils.refreshText(content["loginScreen"]["password"], "Billy Serif");
			}
			
			InputFieldUtil.setUpFieldToScroll(password,shellApi);
			TextUtils.refreshText(content["loginScreen"]["usernameHint"], FONT);
			TextUtils.refreshText(content["loginScreen"]["passwordHint"], FONT);
			userName.text = password.text = "";
			
			userName.addEventListener(KeyboardEvent.KEY_DOWN, checkPressedEnter);
			password.addEventListener(KeyboardEvent.KEY_DOWN, checkPressedEnter);
			
			userName.addEventListener(FocusEvent.FOCUS_IN, Command.create(showHintOnFocusChange, true) );
			userName.addEventListener(FocusEvent.FOCUS_OUT, Command.create(showHintOnFocusChange, false) );
			
			password.addEventListener(FocusEvent.FOCUS_IN, Command.create(showHintOnFocusChange, true) );
			password.addEventListener(FocusEvent.FOCUS_OUT, Command.create(showHintOnFocusChange, false) );
			
			//speciial case for the forgot password button having much different functionality
			//also the length of text needs to have smaller texts
			var clip:MovieClip = content["loginScreen"]["forgotPassword"];
			var tf:TextField = clip["btn"]["text"];
			var format:TextFormat = tf.getTextFormat();
			format.size = 16;
			tf.setTextFormat(format);
			tf.defaultTextFormat = format;
			
			forgotPassword = ButtonCreator.createButtonEntity(clip, this, onForgotPassword);
			var context:ContextButton = new ContextButton(clip["btn"], FONT);
			context.Update("FORGOT PASSWORD?", FORGOT,clip.name);
			forgotPassword.add(context).add(new Id(clip.name));
			var interaction:Interaction = forgotPassword.get(Interaction);
			interaction.over.add(onHover);
			
			EntityUtils.visible(forgotPassword, false);
			
			ContextButton(login.get(ContextButton)).Update("SIGN IN", -1, PLAY);
		}
		
		private function showHintOnFocusChange(event:FocusEvent, inFocus:Boolean = true):void
		{
			targetTF = event.currentTarget as TextField;
			var hint:DisplayObject = targetTF.parent[targetTF.name+"Hint"];
			trace(targetTF.name + " : " + hint + " : " + targetTF.text + " : " + inFocus);
			if(targetTF.text == "" && hint)
			{
				hint.visible = !inFocus;
			}
		}
		
		private function onForgotPassword(entity:Entity):void
		{
			var dialog:ConfirmationDialogBox = addChildGroup(new ConfirmationDialogBox
				(1,"Send an email with instructions to reset your password to the parent address associated with your account?"
					,sendEmailReminder, null, true)) as ConfirmationDialogBox;
			dialog.init(overlayContainer);
		}
		
		private function sendEmailReminder():void
		{
			var loadVars:URLVariables = new URLVariables();
			loadVars.login = keyInfo.login;
			loadVars.dbid = keyInfo.dbid;
			loadVars.action = "resetPasswordRequest";
			
			var request:URLRequest = new URLRequest(shellApi.siteProxy.secureHost+"/store/password_recovery.php");
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, onPasswordResetSuccess);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onPasswordResetFailure);
			request.method = URLRequestMethod.POST;
			request.data = loadVars;
			
			urlLoader.load(request);
		}
		
		protected function onPasswordResetFailure(event:IOErrorEvent):void
		{
			removeListeners(event, onPasswordResetSuccess, onPasswordResetFailure);
		}
		
		protected function onPasswordResetSuccess(event:Event):void
		{
			removeListeners(event, onPasswordResetSuccess, onPasswordResetFailure);
			// TODO Auto-generated method stub
			var dialog:ConfirmationDialogBox = addChildGroup(new ConfirmationDialogBox
				(1,"An Email has been sent to your parent account with instructions to reset your password.")) as ConfirmationDialogBox;
			
			dialog.init(overlayContainer);
		}
		
		protected function checkPressedEnter(event:KeyboardEvent):void
		{
			if(this.paused || !this.isReady)
				return;
			
			targetTF = event.currentTarget as TextField;
			
			if(event.keyCode == Keyboard.ENTER)
			{
				if(targetTF == userName  && userName.text != "" && password.text == "")
					groupContainer.stage.focus = targetTF = password;
				else if(targetTF.text != "")
				{
					changeState(PLAY);
				}
				return;
			}
		}
		// having a function for fetching new names
		// if the player clicks a retry button would be cool
		// get the list of first and last names from the cms
		//private const GET_NAMES:String = "https://E300018ZDdAx.preview.gamesparks.net/callback/E300018ZDdAx/generateName/YR5w9F53GYeMsP8LTBqijeeAsPM66v7J";
		private function getNames():void
		{
			trace("getNames");
			var postVars:URLVariables = new URLVariables();
			postVars.count = 10
			
			var url:String = super.shellApi.siteProxy.secureHost + "/generate_names.php";
			var req:URLRequest = new URLRequest(url);
			req.method = URLRequestMethod.POST;
			req.data = postVars;
			
			var loader:URLLoader = new URLLoader(req);
			loader.addEventListener(Event.COMPLETE,check);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onGetNameError);
			loader.load(req);
		}
		
		protected function onGetNameError(event:IOErrorEvent):void
		{
			shellApi.logWWW(event.errorID, event.text);
			removeListeners(event, check, onGetNameError);
		}
		
		protected function check(event:Event):void
		{
			trace("check names from cms");
			removeListeners(event, check, onGetNameError);
			if(event.target.data != null)
			{
				var data:Object = JSON.parse(event.target.data);
				var answer:String = data.answer;
				if(answer == "ok")
				{
					first_names = data["first_names"];
					last_names = data["last_names"];
					setUpDials();
					dummy = characterGroup.createDummy("dummy",startLook,"right","",screen["npcPlatform"]["island"]["platform"]["charContainer"], this, dummyLoaded,true,1);
				}
				else
				{
					trace(answer);
				}
			}
			else
			{
				trace("Name generation response was empty");
			}
		}
		
		private function setUpDials():void
		{
			trace("setUpDials");
			var clip:MovieClip = content["nameDial"];
			nameDial = DialGroup.setUpDialContainer(this,clip);
			firstNames = DialGroup.createDial(nameDial, clip["values"]["left"],"buttonLeftUp","buttonLeftDown", FONT).get(AgeDial);
			lastNames = DialGroup.createDial(nameDial, clip["values"]["right"],"buttonRightUp","buttonRightDown", FONT).get(AgeDial);
			
			nameDisplay = TextUtils.refreshText(clip["nameDisplay"], FONT);
			trace("Name display size: " + nameDisplay.getTextFormat().size + " vs. font size: " + TEXT_SIZE);
			
			firstNames.dialChanged.add(nameDialUpdated);
			lastNames.dialChanged.add(nameDialUpdated);
			
			firstNames.resetValues(first_names);
			firstNames.updatePool(4,TEXT_SIZE);
			lastNames.resetValues(last_names);
			lastNames.updatePool(4,TEXT_SIZE);
			firstNames.dialChanged.add(nameDialUpdated);
			lastNames.dialChanged.add(nameDialUpdated);
			
			clip = content["ageDial"];
			ageDial = DialGroup.setUpDialContainer(this, clip);
			agesDial = DialGroup.createDial(ageDial, clip["values"]["age"],"leftArrow","rightArrow", FONT).get(AgeDial);
			agesDial.dialChanged.add(ageDialUpdated);
			// making sure that text clone is centered properly
			agesDial.textClone = TextUtils.refreshText(agesDial.textClone, FONT);
			agesDial.updateTextField(agesDial.textClone, NUM_SIZE);
			agesDial.textClone.y = - agesDial.textClone.height/2;
			//set up dial to be horizontal
			agesDial.axis = "x";
			agesDial.offset = 250;
			agesDial.resetValues(ages);
			agesDial.updatePool(4,NUM_SIZE);
		}
		
		private function ageDialUpdated(dial:AgeDial):void
		{
			if(supressInitAge)
			{
				supressInitAge = false;
				return;
			}
			customizeTracking("NewUserAgeSelected", dial.current.text);
		}
		
		private function nameDialUpdated(dial:AgeDial):void
		{
			nameDisplay.text = firstNames.current.text + " " + lastNames.current.text;
			if(supressInitFirstName && dial == firstNames)
			{
				supressInitFirstName = false;
				return;
			}
			if(supressInitLastName && dial == lastNames)
			{
				supressInitLastName = false;
				return;
			}
			var namePart:String = dial == firstNames?"First":"Last"
			customizeTracking("NewUserNameSelected",namePart, dial.current.text);
		}
		
		private function dummyLoaded(entity:Entity):void
		{
			trace("dummyLoaded");
			creationGroup = addChildGroup(new CharacterCreation(content["characterCreation"],null, dummy)) as CharacterCreation;
			getPartsFromCMS();
		}
		
		private function getPartsFromCMS():void
		{
			var postVars:URLVariables = new URLVariables();
			
			var url:String = super.shellApi.siteProxy.secureHost + "/get_avatar_parts.php";
			var req:URLRequest = new URLRequest(url);
			req.method = URLRequestMethod.GET;
			req.data = postVars;
			
			var loader:URLLoader = new URLLoader(req);
			loader.addEventListener(Event.COMPLETE,getParts);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onGetPartsError);
			loader.load(req);
		}
		
		protected function onGetPartsError(event:IOErrorEvent):void
		{
			shellApi.logWWW(event.errorID, event.text);
			removeListeners(event, getParts, onGetPartsError);
			getParts(null);
		}
		
		private function removeListeners(listener:Object, onComplete:Function, onError:Function):void
		{
			if(listener == null)
				return;
			
			if(listener is Event || listener is IOErrorEvent)
			{
				listener = listener.target;
			}
			
			listener.removeEventListener(Event.COMPLETE, onComplete);
			listener.removeEventListener(IOErrorEvent.IO_ERROR, onError);
		}
		
		private function getParts(event:Event):void
		{
			trace("getParts");
			removeListeners(event, getParts, onGetPartsError);
			if(event && event.target.data != null)
			{
				var data:Object = JSON.parse(event.target.data);
				boyLooks = new CharLookLibrary(data.M);
				girlLooks = new CharLookLibrary(data.F);
				allLooks = new CharLookLibrary(data.M);
				allLooks.addFromObject(data.F);
				neutralLooks = new CharLookLibrary(data.N);
				var dontCare:Array = [ SkinUtils.HAIR_COLOR, SkinUtils.SKIN_COLOR, SkinUtils.EYE_STATE, SkinUtils.GENDER];
				for (var type:String in allLooks.Parts)
				{
					if(dontCare.indexOf(type) == -1)
						allLooks.randomizeCategory(type);
				}
			}
			else
			{
				trace("Get parts response was empty using fall back instead");
				var hairColors:Array	=[0x8b0f07,0x1b110b,0x570903,0xdf702f,0xb96826,0xbe5116,0xefeeec,0xfac524,0xfffbd5,0x543525,0xe32e04,0xff7700,0xfff000,0x41f65a,0x1bf1e9,0x431bf1,0xad1bf1,0xf11bad];
				var skinColors:Array	=[0xfdeee6,0xffe5d8,0xfddacf,0xfbd0be,0xf1c0ab,0xe9bc9b,0xf9cba8,0xf0b892,0xf8d4ac,0xecc08f,0x946439,0xe3b27b,0xdb9f69,0xc9915f,0xb07e50,0xa37246,0xd5a95b,0xdeb979];
				var eyes:Array 			= [EyeSystem.OPEN+"_male", EyeSystem.SQUINT+"_male", EyeSystem.OPEN+"_female", EyeSystem.SQUINT+"_female"];
				
				var boyHairs:Array 		= ["char1", "char2", "char3", "char4", "char5", "char6", "char7", "char8", "char9", "char10","char11","char12","char13","char14","char15","char16","char17","char18","char19","char20","char21"];
				var boyMouths:Array 	= [1,15,"pPharaoh","barPatron1","thinking","sponsor_JE","hashimoto","montgomery","eatSalad","pMagic1","pPunkGuy5","pNerd","pVampire_boy","Nessie_tourist","fisherman","pFool","pDisco_King","wwAnnie","steamZach","sponsorAlphaOmega","gardener"];
				var boyShirts:Array 	= ["char1", "char2", "char3", "char4", "char5", "char6", "char7", "char8", "char9", "char10","char11","char12","char13","char14","char15","char16","char17","char18","char19","char20","char21"];
				var boyPants:Array 		= ["char1", "char2", "char3", "char4", "char5", "char6", "char7", "char8", "char9", "char10","char11","char12","char13","char14","char15","char16","char17","char18","char19","char20","char21"];
				
				var girlHairs:Array 	= ["char22","char23","char24","char25","char26","char27","char28","char29","char30","char31","char32","char33","char34","char35","char36","char37","char38","char39","char40","char41","char42"];
				var girlMouths:Array 	= [1,"sponsorLM_Stella","pDisco_Queen","pPopGirl1","sponsorPinoFairy","pSheDevil","sponsor_selenaG","hashimoto","FrankBride","witch","sponsorHeatherG","sponsorEC1","skullNavigator","GpromoDaphne","pBallerina1","athena","pVampire_girl2","pOutlaw_girls","gardener","pNerd","p_SeaCaptain_girl"];
				var girlShirts:Array 	= ["char22","char23","char24","char25","char26","char27","char28","char29","char30","char31","char32","char33","char34","char35","char36","char37","char38","char39","char40","char41","char42"];
				var girlPants:Array 	= ["char22","char23","char24","char25","char26","char27","char28","char29","char30","char31","char32","char33","char34","char35","char36","char37","char38","char39","char40","char41","char42"];
				
				var test:Dictionary = new Dictionary();
				
				test["gender"] = [SkinUtils.GENDER_MALE];
				test["eyeState"] = eyes;
				test["hairColor"] = hairColors;
				test["skinColor"] = skinColors;
				test["hair"] = boyHairs;
				test["mouth"] = boyMouths;
				test["shirt"] = boyShirts;
				test["pants"] = boyPants;
				
				//test string is what i will recieve from cms
				var testString:String = CharLookLibrary.toJson(test);
				boyLooks = new CharLookLibrary(testString);
				
				test = new Dictionary();
				test["gender"] = [SkinUtils.GENDER_FEMALE];
				test["eyeState"] = eyes;
				test["hairColor"] = hairColors;
				test["skinColor"] = skinColors;
				test["hair"]= girlHairs;
				test["mouth"] = girlMouths;
				test["shirt"] = girlShirts;
				test["pants"] = girlPants;
				
				testString = CharLookLibrary.toJson(test);
				girlLooks = new CharLookLibrary(testString);
			}
			// change based on what dan sends along with login or main
			if(startNewChar)
			{
				EntityUtils.visible(backToLogin, false);
				EntityUtils.visible(next, false);
				EntityUtils.visible(back, false);
				SceneUtil.delay(this, 5,Command.create(changeState,NEXT)).countByUpdate = true;
			}
			else
				prepareState(null);
			
			var lso:SharedObject = ProxyUtils.as2lso;
			lso.clear();//start out with a clean slate
			fullyLoaded = true;
			super.loaded();
		}
		
		private function setUpGenderButtons():void
		{
			trace("setUpGenderButtons")
			for(var i:int = 0; i < genders.length; i++)
			{
				var gen:String = genders[i];
				var clip:MovieClip = content["genderSelect"][gen+"Btn"];
				var child:MovieClip = clip["button"]["face"];
				//child.mouseChildren = child.mouseEnabled = false;
				var face:Entity = TimelineUtils.convertClip(child, this, null, null, false);
				face.add(new Id("face"+gen));
				var btn:Entity = ButtonCreator.createButtonEntity(clip, this, Command.create(clickedGenderButton, gen),null,null,null,false).add(new Id(clip.name));
				var interaction:Interaction = btn.get(Interaction);
				interaction.over.add(onHover);
			}
		}
		
		private function onHover(button:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "ui_roll_over.mp3", 1, false, SoundModifier.EFFECTS);
		}
		
		private function clickedGenderButton(button:Entity, gender:String):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "ui_button_click.mp3", 1, false, SoundModifier.EFFECTS);
			this.gender = gender;
			var btn:Entity;
			
			customizeTracking("NewUserGenderSelected", gender == SkinUtils.GENDER_MALE?"M":"F");
			/*// don't want genders impacting looks before customization begins
			var look:LookData;
			if( gender == SkinUtils.GENDER_MALE)
			look = boyLooks.createLook();
			else
			look = girlLooks.createLook();
			
			UpdateDummy(look);
			*/
			//select/deslect buttons based which one was clicked
			for(var i:int = 0; i < genders.length; i++)
			{
				var gen:String = genders[i];
				btn = getEntityById(gen+"Btn");
				var label:String = gender == gen? "select":"deselect";
				Timeline(getEntityById("face"+gen).get(Timeline)).gotoAndStop(label);
				var spatial:Spatial = btn.get(Spatial);
				spatial.scale = label == "select"? 1.25:.75;
			}
		}
		
		private function resetGender():void
		{
			gender = null;
			var btn:Entity;
			for(var i:int = 0; i < genders.length; i++)
			{
				var gen:String = genders[i];
				btn = getEntityById(gen+"Btn");
				var label:String = "deselect";
				Timeline(getEntityById("face"+gen).get(Timeline)).gotoAndStop(label);
				var spatial:Spatial = btn.get(Spatial);
				spatial.scale = 1;
			}
		}
		
		private function setUpSetPieces():void
		{
			trace("setUpSetPieces");
			var setPieces:Array = [content["loginScreen"],screen["npcPlatform"]["island"],
				content["genderSelect"], content["characterCreation"], content["emailReminder"]];
			for(var i:int = 0; i < setPieces.length; i++)
			{
				var clip:MovieClip = setPieces[i];
				var entity:Entity = EntityUtils.createSpatialEntity(this, clip);
				this[clip.name] = entity;
				var title:TextField = clip["title"];
				if(title)
				{
					title = TextUtils.refreshText(title, FONT);
					title.autoSize = TextFieldAutoSize.CENTER;
					title.x = -title.width/2;
				}
			}
		}
		
		private function setUpContextButtons():void
		{
			trace("setUpContextButtons");
			var buttons:Array = [content[NEXT], content[BACK], content[RTRN], 
				screen["npcPlatform"]["island"]["create"], content["loginScreen"]["login"],
				content["emailReminder"]["later"],content["emailReminder"]["submit"]];
			var colors:Array = [GREEN, ORANGE, GREEN, PURPLE, MAROON, PURPLE, MAROON];
			for(var i:int = 0; i < buttons.length; i++)
			{
				var clip:MovieClip = buttons[i];
				var entity:Entity = ButtonCreator.createButtonEntity(clip, this, clickButton);
				var context:ContextButton = new ContextButton(clip["btn"], FONT);
				context.Update(clip.name.toUpperCase(), colors[i],clip.name);
				entity.add(context).add(new Id(clip.name));
				var interaction:Interaction = entity.get(Interaction);
				interaction.over.add(onHover);
				this[clip.name] = entity;
			}
		}
		
		private function clickButton(entity:Entity):void
		{
			var context:ContextButton = entity.get(ContextButton);
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "ui_button_click.mp3", 1, false, SoundModifier.EFFECTS);
			if(!fullyLoaded || !shellApi.networkAvailable())
			{
				openWarningPopup("could not connect to servers check connection and try again");
				return;
			}
			// update profile based on the current state
			switch(state)
			{
				case AGE_GENDER:
				{
					age = int(agesDial.current.text.substr(0,2));//ignore any text beyond 2 digits
					if(gender == null && context.context == NEXT)
					{
						openWarningPopup("You have to pick a gender.");
						return;
					}
					if(context.context == NEXT)
					{
						shellApi.profileManager.active.age = age;
						shellApi.profileManager.active.gender = gender;
						customizeTracking("NewUserDemoCompleted");
					}
					break;
				}
				case NAME_GENERATION:
				{
					firstName = firstNames.current.text;
					lastName = lastNames.current.text;
					break;
				}
				case CHARCER_CREATION:
				{
					if(context.context == NEXT)
					{
						var look:LookData = SkinUtils.getLook(dummy);
						var eventName:String = "CharacterCreationLook";
						var parts:Array = [SkinUtils.HAIR, SkinUtils.HAIR_COLOR, SkinUtils.MOUTH, SkinUtils.SHIRT, SkinUtils.PANTS, SkinUtils.SKIN_COLOR];
						for(var i:int = 0; i < parts.length; i++)
						{
							var part:String = parts[i];
							switch(part)
							{
								case SkinUtils.SHIRT:
									part = "top";
									break;
								case SkinUtils.PANTS:
									part = "bottom";
									break;
							}
							part = part.substr(0,1).toUpperCase()+part.substr(1);
							customizeTracking(eventName, part, look.getValue(parts[i]));
						}
						customizeTracking("NewUserAvatarCompleted");
					}
					break;
				}
				case PARENT_EMAIL:
				{
					if(context.context == PLAY)
					{
						evaluateParentEmail();
					}
					else
					{
						SceneUtil.lockInput(this);
						shellApi.ShellBase.postBuildProcess();
					}
					return;
				}
				default://init
				{
					if(context.context == NEXT)
					{
						customizeTracking("NewUserClicked");
					}
					else
					{
						customizeTracking("LoginClicked");
					}
				}
			}
			changeState(context.context);
		}
		
		private function evaluateParentEmail():void
		{
			var validEmail:Boolean = false;
			var message:String = "";
			if(DataUtils.validString(email.text))
			{
				if(checkEmailString(email.text))
				{
					validEmail = true;
				}
				else
				{
					message = "This email is not valid.";
				}
			}
			else
			{
				message = "Please enter a valid email address.";
			}
			emailError.text = message;
			if(validEmail)
			{
				submitParentEmail();
				SceneUtil.lockInput(this);
			}
		}
		
		private function checkEmailString(email:String):Boolean
		{
			var emailPattern_str:String = '^[^@ ]+\\@[-\\d\\w]+(\\.[-\\d\\w]+)+$';
			var flags:String = 'gim'; // global, case Insensitive, multiline			
			var email_re:RegExp = new RegExp(emailPattern_str, flags);			
			return(email_re.test(email));
		}
		
		private function submitParentEmail():void
		{
			var loadVars:URLVariables = new URLVariables();
			loadVars.login = this.shellApi.profileManager.active.login;
			loadVars.pass_hash = this.shellApi.profileManager.active.pass_hash;
			loadVars.dbid = String(this.shellApi.profileManager.active.dbid);
			loadVars.parent_email = email.text;
			loadVars.action = "insertParentEmail";
			
			var request:URLRequest = new URLRequest(shellApi.siteProxy.secureHost+ shellApi.siteProxy.commData.parentalEmailURL);
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, onEmailSuccess);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onEmailError);
			request.method = URLRequestMethod.POST;
			request.data = loadVars;
			
			urlLoader.load(request);
		}
		
		protected function onEmailError(event:IOErrorEvent):void
		{
			trace("there was an error submitting email + " + event.toString());
			onEmailSuccess(null);
		}
		
		protected function onEmailSuccess(event:Event):void
		{
			trace("continue loading into game");
			shellApi.ShellBase.postBuildProcess();
		}
		
		private function openWarningPopup(message:String, onComplete:Function = null):void
		{
			var warning:WarningPopup = addChildGroup(new WarningPopup(overlayContainer)) as WarningPopup;
			warning.ConfigPopup("oops", message);
			warning.removed.addOnce(resetFocus);
			if(onComplete)
				warning.removed.addOnce(onComplete);
		}
		
		private function resetFocus(group:Popup):void
		{
			groupContainer.stage.focus = targetTF;
		}
		
		// depending on the context, move through the states of character creation
		private function changeState(context:String):void
		{
			switch(context)
			{
				case RTRN:
				{
					if(this.state == INIT)
						this.state = RETURN_USER;
					else
						this.state = INIT;
					break;
				}
				case NEXT:
				{
					if(profiles >= MAX_PROFILES)
					{
						this.state = RETURN_USER;
						overwriteProfile = true;
						break;
					}
					this.state++;
					break;
				}
				case BACK:
				{
					if(state == INIT)
					{
						customizeTracking("NewUserParentEmailReminderShown");
					}
					else
					{
						customizeTracking("NewUser"+STATE_NAMES[state+1]+"BackClicked");
					}
					this.state--;
					break;
				}
				case PLAY:
				{
					switch(state)
					{
						case INIT:
						{
							if(userName.text.length > 0 && password.text.length > 0)
							{
								// if not already requested login
								if (!requestedLogin)
								{
									//if you have reached the max, and the profile does not already exist change to delete profile state
									if(profiles >= MAX_PROFILES && shellApi.profileManager.getProfile(userName.text) == null)
									{
										this.state = RETURN_USER;
										overwriteProfile = true;
										prepareState(context);
										return;
									}
									SceneUtil.lockInput(this);
									requestedLogin = true;
									loginProfile.login(userName.text, password.text, onLogin);
								}
							}
							else
							{
								openWarningPopup("you need to enter a username and password!");
							}
							break;
						}
						case PARENT_EMAIL:
						{
							evaluateParentEmail();
							break;
						}
						default:
						{
							if(requestedLogin)
								return;
							requestedLogin = true;
							fillOutNewPlayerData();
							fillOutAs2Profile();
							customizeTracking("NewUserSetupCompleted", firstName, lastName);
							break;
						}
					}
					return;
				}
			}
			prepareState(context);
		}
		
		private function onLogin(success:Boolean, message:String, keyInfo:Object):void
		{
			if(state == RETURN_USER)
			{
				profileGroup = null;
			}
			
			trace("login successful? " + success + " : " + message);
			var hasParentEmail:Boolean = false;
			this.keyInfo = keyInfo;
			if(keyInfo != null)
				hasParentEmail = keyInfo.parentEmailStatus == "Verified";
			
			var eventName:String = "SuccessfulLogin";
			
			if(success)
			{
				AppConfig.retrieveFromExternal = true;
				if(true)
				{
					AppConfig.storeToExternal = true;
					AppConfig.retrieveFromExternal = true;
				}
				
				if(!hasParentEmail)
					hasParentEmail = keyInfo.parentEmailStatus == "Pending";
				
				shellApi.ShellBase.complete.addOnce(postBuildProcessComplete);
				if(Math.random() * PARENT_EMAIL_REMINDER_RATE == 0 && !hasParentEmail)
				{
					changeState(BACK);
					var startIndex:int = reminderMessage.text.indexOf(",") + 2;//accounting for the space
					var endIndex:int = reminderMessage.text.indexOf("!");
					var oldName:String = reminderMessage.text.substr(startIndex, endIndex-startIndex);
					var newName:String = shellApi.profileManager.active.avatarName;
					reminderMessage.text = reminderMessage.text.replace(oldName, newName);
				}
				else
				{
					shellApi.ShellBase.resetPostBuildProcess();
					shellApi.ShellBase.postBuildProcess();
				}
			}
			else
			{
				if(state == RETURN_USER)
				{
					changeState(RTRN);
				}
				requestedLogin = false;
				if(message == LoginResult.PASSWORD_INVALID)
				{
					eventName = "InvalidPassword";
					groupContainer.stage.focus = targetTF = password;
				}
				else
				{
					eventName = "InvalidUsername";
					groupContainer.stage.focus = targetTF = userName;
				}
				SceneUtil.lockInput(this, false);
				openWarningPopup(message);
				if(hasParentEmail)
				{
					EntityUtils.visible(forgotPassword);
				}
			}
			
			customizeTracking(eventName);
		}
		
		private function postBuildProcessComplete(shell:Shell):void
		{
			trace("Post build process complete");
			shellApi.profileManager.activeLogin = userName.text;
			SceneUtil.lockInput(this, false);
			fillOutAs2Profile();
		}
		
		// handle things that require loading before moving on
		private function prepareState(context:String):void
		{
			var look:LookData;
			switch(state)
			{
				case NAME_GENERATION:
				{
					setUpState();
					break;
				}
				case AGE_GENDER:
				{
					targetTF = null;
					UpdateDummy(customLook,setUpState);
					break;
				}
				case CHARCER_CREATION:
				{
					if(context == NEXT)
					{
						SceneUtil.lockInput(this);
						creationGroup.libraryReady.addOnce(
							function():void
							{
								/*
								if( gender == SkinUtils.GENDER_MALE)
								look = boyLooks.createLook();
								else
								look = girlLooks.createLook();
								*/
								trace("looks ready? "+neutralLooks == null);
								look = neutralLooks.createLook();
								trace("looks ready? "+look == null);
								UpdateDummy(look, setUpState);
							}
						);
						//creationGroup.ChangeLibraries(gender == SkinUtils.GENDER_MALE?boyLooks:girlLooks);
						creationGroup.ChangeLibraries(allLooks);
					}
					else
					{
						setUpState();
					}
					break;
				}
				case PARENT_EMAIL:
				{
					targetTF = email;
					setUpState();
					break;
				}
				case RETURN_USER:
				{
					targetTF = null;
					this.profileGroup = this.addChildGroup(new ProfileGroup(this.screen.content, this.overwriteProfile)) as ProfileGroup;
					this.profileGroup.clicked.addOnce(this.getProfile);
					if(profiles > 1)
						setUpState();
					break;
				}
				default://INIT
				{
					if(profileGroup)
					{
						profileGroup.close(null);
						profileGroup = null;
					}
					//targetTF = userName;
					SceneUtil.lockInput(this);
					UpdateDummy(startLook,setUpState);
					break;
				}
			}
			groupContainer.stage.focus = targetTF;
		}
		
		private function getProfile(profileData:ProfileData):void
		{
			if(overwriteProfile)
			{
				profiles--;
				profileGroup = null;
				overwriteProfile = false;
				shellApi.profileManager.remove(profileData);
				changeState(RTRN);
			}
			else
			{
				if(DataUtils.validString(profileData.pass_hash))
				{
					userName.text = profileData.login;
					var hint:DisplayObject = userName.parent[userName.name+"Hint"];
					hint.visible = false;
					if(!shellApi.networkAvailable())
					{
						openWarningPopup("could not connect to servers check connection and try again");
						return;
					}
					if (!requestedLogin)
					{
						SceneUtil.lockInput(this);
						requestedLogin = true;
						loginProfile.login(profileData.login, profileData.pass_hash, onLogin, false);
					}
				}
				else
				{
					shellApi.profileManager.activeLogin = profileData.login;
					
					this.shellApi.island = null;
					
					this.shellApi.gameEventManager.restore(this.shellApi.profileManager.active.events);
					this.shellApi.itemManager.restoreSets(this.shellApi.profileManager.active.items);
					
					startGame();
				}
			}
		}
		
		private function getNextDefaultProfileLoginName():String
		{
			var index:uint = 0;
			var login:String = "default" + index;
			while(this.shellApi.profileManager.getProfile(login))
			{
				login = "default" + ++index;
			}
			return login;
		}
		// show/hide/rename/reposition pieces of ui based on state and context
		private function setUpState(...args):void
		{
			switch(state)
			{
				case AGE_GENDER:
				{
					EntityUtils.visible(next,true);
					EntityUtils.visible(back, true);
					EntityUtils.visible(create, false);
					
					TweenUtils.entityTo(genderSelect, Spatial,1,{x:shellApi.viewportWidth / 4});
					TweenUtils.entityTo(ageDial, Spatial,1,{x:shellApi.viewportWidth / 4});
					TweenUtils.entityTo(island, Spatial,1,{x:-shellApi.viewportWidth / 4});
					TweenUtils.entityTo(loginScreen, Spatial,1,{x:shellApi.viewportWidth});
					TweenUtils.entityTo(characterCreation, Spatial,1,{y:shellApi.viewportHeight});
					
					break;
				}
				case CHARCER_CREATION:
				{
					EntityUtils.visible(next,true);
					if(testChanges)
					{
						EntityUtils.visible(back, false);
						EntityUtils.visible(backToLogin, true);
					}
					else
						EntityUtils.visible(back, true);
					
					EntityUtils.visible(create, false);
					if(returnUser)
						EntityUtils.visible(returnUser, false);
					
					ContextButton(next.get(ContextButton)).Update(NEXT.toUpperCase(), -1, NEXT);
					
					TweenUtils.entityTo(island, Spatial,1,{x:0});
					TweenUtils.entityTo(characterCreation, Spatial,1,{y:shellApi.viewportHeight /2});
					TweenUtils.entityTo(genderSelect, Spatial,1,{x:shellApi.viewportWidth});
					TweenUtils.entityTo(nameDial, Spatial,1,{x:shellApi.viewportWidth});
					TweenUtils.entityTo(ageDial, Spatial,1,{x:shellApi.viewportWidth});
					TweenUtils.entityTo(loginScreen, Spatial,1,{x:shellApi.viewportWidth});
					
					break;
				}
				case NAME_GENERATION:
				{
					ContextButton(next.get(ContextButton)).Update(PLAY.toUpperCase(), -1, PLAY);
					EntityUtils.visible(back, true);
					
					TweenUtils.entityTo(nameDial, Spatial,1,{x:shellApi.viewportWidth /4});
					TweenUtils.entityTo(island, Spatial,1,{x:-shellApi.viewportWidth /4});
					TweenUtils.entityTo(characterCreation, Spatial,1,{y:shellApi.viewportHeight});
					
					break;
				}
				case PARENT_EMAIL:
				{
					TweenUtils.entityTo(emailReminder, Spatial,1,{y:0});
					break;
				}
				case RETURN_USER:
				{
					ContextButton(returnUser.get(ContextButton)).Update("CANCEL", ORANGE, RTRN);
					
					TweenUtils.entityTo(island, Spatial,1,{x:-shellApi.viewportWidth});
					TweenUtils.entityTo(loginScreen, Spatial,1,{x:shellApi.viewportWidth});
					break;
				}
				default://INIT
				{
					EntityUtils.visible(next,false);
					EntityUtils.visible(back, false);
					if(testChanges)
					{
						EntityUtils.visible(create, false);
						EntityUtils.visible(backToLogin, false);
					}
					else
						EntityUtils.visible(create, true);
					
					if(returnUser)
					{
						EntityUtils.visible(returnUser, true);
						ContextButton(returnUser.get(ContextButton)).Update("RETURNING PLAYER", GREEN, RTRN);
					}
					TweenUtils.entityTo(island, Spatial,1,{x:-shellApi.viewportWidth /4});
					TweenUtils.entityTo(loginScreen, Spatial,1,{x:shellApi.viewportWidth /4});
					TweenUtils.entityTo(genderSelect, Spatial,1,{x:shellApi.viewportWidth});
					TweenUtils.entityTo(nameDial, Spatial,1,{x:shellApi.viewportWidth});
					TweenUtils.entityTo(ageDial, Spatial,1,{x:shellApi.viewportWidth});
					TweenUtils.entityTo(emailReminder, Spatial,1,{y:shellApi.viewportHeight});
					TweenUtils.entityTo(characterCreation, Spatial,1,{y:shellApi.viewportHeight});
					
					break;
				}
			}
			customizeTracking("NewUser"+STATE_NAMES[state+1]+"StepStarted");
			
			SceneUtil.lockInput(this,false);
			pole.gotoAndStop(state);
		}
		
		private function UpdateDummy(look:LookData, onComplete:Function = null):void
		{
			if(look.getAspect(SkinUtils.EYES) == null)
				look.applyAspect(new LookAspectData(SkinUtils.EYES, SkinUtils.getDefaultPart(SkinUtils.EYES)));
			
			look.fillWithEmpty();
			
			SkinUtils.applyLook(dummy, look,true,onComplete);
			var eyeState:String = look.getValue(SkinUtils.EYE_STATE);
			if(DataUtils.validString(eyeState))
			{
				SkinUtils.setEyeStates(dummy, eyeState);
			}
			
			CharUtils.setAnim(dummy, Pop);
		}
		
		private function fillOutNewPlayerData():void
		{
			var look:LookData = SkinUtils.getLook(dummy);
			var lookConverter:LookConverter = new LookConverter();
			
			if(true)
			{
				AppConfig.storeToExternal = true;
				AppConfig.retrieveFromExternal = true;
			}
			
			shellApi.itemManager.reset();
			shellApi.gameEventManager.reset();
			
			var profileData:ProfileData = new ProfileData(getNextDefaultProfileLoginName());
			profileData.look = lookConverter.playerLookFromLookData(look);
			
			profileData.avatarFirstName = firstName;
			profileData.avatarLastName 	= lastName;
			
			age = int(agesDial.current.text.substr(0,2));//ignore any text beyond 2 digits
			gender = SkinUtils.getSkinPart(dummy, SkinUtils.GENDER).value;
			
			profileData.gender = gender;
			profileData.age = age;
			profileData.isGuest = true;
			profileData.profileComplete = true;
			// was determined that we wanted the fastest dialog speed as default
			profileData.dialogSpeed = Utils.fromDecimal(0.25, Dialog.MIN_DIALOG_SPEED, Dialog.MAX_DIALOG_SPEED);
			
			shellApi.profileManager.add(profileData, true);
			//shellApi.profileManager.setDialogSpeedByAge();
		}
		
		private function startGame():void
		{
			//have to make sure store cards are retrieved before starting the game
			if( true )
			{
				if (MobileStepGetStoreCards.failedToGetCards)
				{
					MobileStepGetStoreCards.getCards(shellApi, Command.create(shellApi.loadScene, Town));
				}
				else
				{
					this.shellApi.loadScene(Town);
				}
			}
			else
			{
				if(doMapABTest)
				{
					//a-b test of town(75%) vs map (25%)
					var sendToMap:Boolean = false;
					var firstTimeMapTest:Boolean = false;
					var charLSO:SharedObject = SharedObject.getLocal("MapAB");
					charLSO.objectEncoding = ObjectEncoding.AMF0;
					shellApi.logWWW(charLSO);
					shellApi.logWWW(charLSO.data);
					if ((charLSO.data.sendToMap == null) && shellApi.profileManager.active.isGuest)
					{
						shellApi.logWWW("Login :: LSO null");
						firstTimeMapTest = true;
						var randNum:Number = (Math.floor(Math.random() * (100 - 0 + 1)) + 0);
						if(randNum <= 35 )
						{
							sendToMap = true;
							shellApi.logWWW("Login :: to Map!");
						}
						if (BrowserStepGetStoreCards.failedToGetCards)
						{
							if(sendToMap)
							{
								charLSO.data.sendToMap = true;
								charLSO.flush();
								BrowserStepGetStoreCards.getCards(shellApi, Command.create(shellApi.loadScene, Map));
								
							}
							else
							{
								charLSO.data.sendToMap = false;
								charLSO.flush();
								BrowserStepGetStoreCards.getCards(shellApi, Command.create(shellApi.loadScene, Town));
							}
						}
						else
						{
							if(sendToMap)
							{
								charLSO.data.sendToMap = true;
								charLSO.flush();
								this.shellApi.loadScene(Map);
							
							}
							else
							{
								charLSO.data.sendToMap = false;
								charLSO.flush();
								this.shellApi.loadScene(Town);
							}
						}
					}
					else
					{	
						if(charLSO.data.sendToMap)
						{
							shellApi.logWWW("Login :: LSO Found! to Map!");
							this.shellApi.loadScene(Map);
						}
						else
						{
							shellApi.logWWW("Login :: LSO not found, to Town!");
							this.shellApi.loadScene(Town);
						}
					}
					
					
					if(firstTimeMapTest == true)
					{
						if(sendToMap)
							shellApi.track("ABTest_choice","Map","","ABTest_DirectMap");
						else
							shellApi.track("ABTest_choice","Town","","ABTest_DirectMap");
					}
					else
					{
						if(sendToMap)
							shellApi.track("ABTest_chosen","Map","","ABTest_DirectMap");
						else
							shellApi.track("ABTest_chosen","Town","","ABTest_DirectMap");
					}
				}
				else
				{
					if (BrowserStepGetStoreCards.failedToGetCards)
					{
						BrowserStepGetStoreCards.getCards(shellApi, Command.create(shellApi.loadScene, Town));
					}
					else
					{
						this.shellApi.loadScene(Town);
					}
				}
			}
		}
		
		// fills out as2 lso and then starts the game
		private function fillOutAs2Profile():void
		{
			var lso:SharedObject = ProxyUtils.as2lso;
			var profile:ProfileData = shellApi.profileManager.active;
			var obj:Object = lso.data;
			obj.password = profile.pass_hash;
			obj.login = profile.login;
			obj.last_x = profile.lastX;
			obj.last_y = profile.lastY;
			obj.firstName = profile.avatarFirstName;
			obj.lastName = profile.avatarLastName;
			
			if(profile.memberStatus == null)
			{
				profile.memberStatus = new MembershipStatus();
				profile.memberStatus.statusCode = MembershipStatus.MEMBERSHIP_NONMEMBER;
			}
			
			obj.mem_status = MembershipStatus.getAS2Status(profile.memberStatus.statusCode);
			
			if(profile.memberStatus.endDate)
				obj.mem_timestamp = profile.memberStatus.endDate.time;
			
			obj.enteringNewIsland = false;
			obj.firstAs3Load = true;
			
			obj.Registred = !profile.isGuest;
			
			obj["game.scenes.hub.town.TownxPos"] = 1650;
			obj["game.scenes.hub.town.TownyPos"] = 0;
			obj.GlobalAS3EmbassyxPos = "Hub";
			obj.age = profile.age;
			obj.GlobalAS3EmbassyyPos = null;
			obj.last_island = profile.previousIsland;
			obj.last_room = profile.lastScene[profile.previousIsland];
			trace(obj.last_island + " :: " + obj.last_room);
			obj.dbid = profile.dbid;
			obj.lineWidth = 1;
			var islandCompletions:Object = new Object();
			for(var island:String in profile.islandCompletes)
			{
				var islandFormat:String = ProxyUtils.isAS2Island(island)?ProxyUtils.convertIslandToAS2Format(island):ProxyUtils.convertIslandToServerFormat(island);
				islandCompletions[islandFormat] = profile.islandCompletes[island];
			}
			obj.islandCompletions = islandCompletions;
			var userData:Object = new Object();
			var val:*;
			for(var field:String in profile._userFields)
			{
				val = profile.userFields[field];
				if(val is Dictionary)
				{
					var islandData:Object = new Object();
					
					for(var islandField:String in val)
					{
						islandData[islandField] = val[islandField];
					}
					userData[field] = islandData;
				}
				else
				{
					userData[field] = val;
				}
			}
			obj.userData = userData;
			var properties:XMLList = describeType(profile.look)..variable;
			for each(var variable:XML in properties) 
			{
				var prop:String = variable.@name;
				val = profile.look[prop];
				
				trace("VARIABLE: " + prop +"VALUE: " + val);
				if(prop == SkinUtils.EYES)
				{
					prop = "eyelidsPos";
					val = 100;
				}
				else if(prop.indexOf("Color") == -1 && prop != SkinUtils.EYE_STATE && prop != SkinUtils.GENDER)
				{
					prop += "Frame";
				}
				if(prop == SkinUtils.EYE_STATE)// eyes are handled really weird
				{
					prop = "eyesFrame";
					switch(val)
					{
						case EyeSystem.SQUINT:
							val = 1;
							break;
						default:
							val = 3;
							break;
					}
				}
				obj[prop] = val;
			}
			obj.lineColor = profile.look.skinColor;
			var gameProperties:Array = ['score', 'wins', 'losses'];
			for(var game:String in profile.scores)
			{
				var gameData:Object = profile.scores[game];
				
				trace(game +": " + JSON.stringify(gameData));
				for(var i:int = 0; i < gameProperties.length; i++)
				{
					prop = gameProperties[i];
					var suffix:String = prop.substr(0,1).toUpperCase() + prop.substr(1);
					obj[game+suffix] = gameData[prop];
				}
			}
			
			//get parent email then start game
			shellApi.siteProxy.call(DataStoreRequest.parentalEmailStatusRequest(), checkParentEmail);
			
			lso.flush();
			
			//create a transit token
			/*
			lso = SharedObject.getLocal('TransitToken', '/');
			lso.clear();
			obj = lso.data;
			obj.GlobalAS3EmbassyxPos = "Hub";
			obj.prevIsland = "Home";
			obj.prevScene = "Home";
			obj.nextScene = "game.scenes.hub.town.Town";
			obj.GlobalAS3EmbassyyPos = null;
			obj.Registred = !profile.isGuest;
			obj.prevDir = "right";
			obj.nextDir = "right";
			obj.prevSelection = "gameplay";
			obj.prevY = -30;
			obj.isGuest = profile.isGuest;
			obj.login = profile.login;
			obj.pass_hash = profile.pass_hash;
			obj.dbid = profile.dbid;
			obj.prevX = 0;
			obj.nextX = 1650;
			var lookConverter:LookConverter = new LookConverter();
			
			obj.look = lookConverter.getLookStringFromLookData(lookConverter.lookDataFromPlayerLook(profile.look));
			lso.flush();
			*/
		}
		
		private function checkParentEmail(popResponse:PopResponse):void
		{
			if(popResponse.succeeded && popResponse.data != null)
			{
				if(popResponse.data.answer == "ok")
				{
					var lso:SharedObject = ProxyUtils.as2lso;
					lso.data.parentEmailStatus = popResponse.data.has_parent_email;
					lso.data.parentEmail = popResponse.data.parent_email;
				}
			}
			
			startGame();
		}
		
		private function traceOutProfileProperties():void
		{
			trace("as2 login data after");
			var lso:SharedObject = ProxyUtils.getAS2LSO("Char");
			var field:String;
			var lsoName:String;
			var lsos:Array = ["Char"];
			for(var i:int = 0; i < lsos.length; i++)
			{
				lsoName = lsos[i];
				lso = ProxyUtils.getAS2LSO(lsoName);
				if(lso)
				{
					trace("found: " + lsoName);
					for(field in lso.data)
					{
						trace(field + ": " + JSON.stringify(lso.data[field]));
					}
				}
				else
				{
					trace(lsoName + " not found.");
				}
			}
			var profile:ProfileData = shellApi.profileManager.active;
			trace("as3 login data");
			trace(profile.toString());
		}
		
		public function customizeTracking(event:String, choice:String = null, subChoice:String = null):void
		{
			if(testChanges)
			{
				if(event.indexOf("NewUser") == 0)
					event = event.replace("NewUser","SplitFlow");
				else
					event = "SplitFlow"+event;
			}
			trace("updated event: " + event);
			var vars:URLVariables = new URLVariables();
			vars.scene = "StartGame";
			shellApi.track(event, choice, subChoice, null, null,NaN, null, vars);
		}
		
		private function addSystems():void
		{
			trace("addSystems");
			this.characterGroup = this.getGroupById("characterGroup") as CharacterGroup;
			if(!characterGroup)
			{
				characterGroup = new CharacterGroup();
				characterGroup.setupGroup(this, content );
			}
			loginProfile = addChildGroup(new FillOutLoginProfile()) as FillOutLoginProfile;
			
			this.addSystem(new RenderSystem());
			this.addSystem(new TweenSystem());
			this.addSystem(new InteractionSystem());
			this.addSystem(new ButtonSystem());
			this.addSystem(new TimelineControlSystem());
			this.addSystem(new TimelineRigSystem());
			this.addSystem(new TimelineClipSystem());
			this.addSystem(new EyeSystem());
		}
	}
}