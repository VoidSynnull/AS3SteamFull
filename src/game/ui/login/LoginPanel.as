package game.ui.login
{
	import com.adobe.crypto.MD5;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.FocusEvent;
	import flash.geom.Rectangle;
	import flash.net.URLVariables;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.group.DisplayGroup;
	import engine.util.Command;
	
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.comm.PopResponse;
	import game.data.profile.ProfileData;
	import game.proxy.DataStoreRequest;
	import game.proxy.GatewayConstants;
	import game.proxy.PopDataStoreRequest;
	import game.util.DataUtils;
	import game.util.DisplayAlignment;
	import game.util.DisplayPositions;
	import game.util.SceneUtil;
	import game.util.ScreenEffects;
	import game.util.SkinUtils;
	import game.util.TextUtils;
	
	import org.osflash.signals.Signal;
	
	public class LoginPanel extends DisplayGroup
	{
		public function LoginPanel(container:DisplayObjectContainer=null)
		{
			super(container);
			
			super.id = GROUP_ID;
			super.groupPrefix = "ui/login/";
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.init(container);
			load();
			_badUsernames = new Vector.<String>();
			_badLogins = new Vector.<Object>();
		}
		
		override public function destroy():void
		{
			_usernameEntryText.removeEventListener(FocusEvent.FOCUS_IN, onUsernameFocusIn);
			_usernameEntryText.removeEventListener(FocusEvent.FOCUS_OUT, onUsernameFocusOut);
			_passwordEntryText.removeEventListener(FocusEvent.FOCUS_IN, onPasswordFocusIn);
			_passwordEntryText.removeEventListener(FocusEvent.FOCUS_OUT, onPasswordFocusOut);
			this.loggedIn.removeAll();
			super.destroy();
		}
		
		override public function load():void
		{
			this.loadFiles(["login.swf"], false, true, this.loaded);
		}
		
		override public function loaded():void
		{
			_display = super.getAsset("login.swf", true) as MovieClip;
			super.groupContainer.addChild(_display);
			_tween = super.getGroupEntityComponent(Tween);
			
			DisplayAlignment.alignToArea(_display, new Rectangle(0, 0, this.shellApi.viewportWidth, this.shellApi.viewportHeight / 2));
			
			_usernameEntry = _display.username;
			_usernameEntryText = _usernameEntry.entry;
			_usernameEntryText = TextUtils.refreshText(_usernameEntryText);
			_usernameEntryText.text = "Username";
			_usernameEntryText.needsSoftKeyboard = true;
			_usernameEntryText.addEventListener(FocusEvent.FOCUS_IN, onUsernameFocusIn);
			_usernameEntryText.addEventListener(FocusEvent.FOCUS_OUT, onUsernameFocusOut);
			
			_passwordEntry = _display.password;
			_passwordEntryText = _passwordEntry.entry;
			_passwordEntryText = TextUtils.refreshText(_passwordEntryText);
			_passwordEntryText.text = "Password";
			_passwordEntryText.needsSoftKeyboard = true;
			_passwordEntryText.addEventListener(FocusEvent.FOCUS_IN, onPasswordFocusIn);
			_passwordEntryText.addEventListener(FocusEvent.FOCUS_OUT, onPasswordFocusOut);
			
			setupButtons();
			
			//createKeyboard();
			
			var screenEffects:ScreenEffects = new ScreenEffects();
			var box:Sprite = screenEffects.createBox(shellApi.viewportWidth, shellApi.viewportHeight, 0x000000);
			box.alpha = .4;
			super.groupContainer.addChildAt(box, 0);
			
			super.loaded();
		}
		
		private function onUsernameFocusIn(event:FocusEvent):void
		{
			var textField:TextField = event.target as TextField;
			textField.stage.softKeyboardInputAreaOfInterest = textField.getBounds(textField.stage);
			if(textField.text.toLowerCase() == "username")
			{
				textField.text = "";
			}
		}
		
		private function onUsernameFocusOut(event:FocusEvent):void
		{
			var textField:TextField = event.target as TextField;
			textField.stage.softKeyboardInputAreaOfInterest = null;
			if(textField.text == "")
			{
				textField.text = "username";
			}
		}
		
		private function onPasswordFocusIn(event:FocusEvent):void
		{
			var textField:TextField = event.target as TextField;
			textField.stage.softKeyboardInputAreaOfInterest = textField.getBounds(textField.stage);
			//textField.displayAsPassword = true;
			if(textField.text.toLowerCase() == "password")
			{
				textField.text = "";
			}
		}
		
		private function onPasswordFocusOut(event:FocusEvent):void
		{
			var textField:TextField = event.target as TextField;
			textField.stage.softKeyboardInputAreaOfInterest = null;
			if(textField.text == "")
			{
				//textField.displayAsPassword = false;
				textField.text = "Password";
			}
		}
		
		private function setupButtons():void
		{
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 20, 0xffffff);
			
			ButtonCreator.addLabel(_display.buttonOk, "Import Look", labelFormat, ButtonCreator.ORIENT_CENTERED);
			_okButton = ButtonCreator.createButtonEntity(_display.buttonOk, this, handleOkClicked);
			ButtonCreator.loadCloseButton(this, this.groupContainer, handleCloseClicked, DisplayPositions.CENTER, 0, 0, false, positionCloseButtonCorrectly);
		}
		
		//Because who knows how ButtonCreator REALLY positions things.
		private function positionCloseButtonCorrectly(entity:Entity):void
		{
			var bounds:Rectangle = _display.getBounds(_display.parent);
			
			Display(entity.get(Display)).isStatic = false;
			
			var spatial:Spatial = entity.get(Spatial);
			spatial.x = bounds.right;
			spatial.y = bounds.top;
		}
		
		private function handleCloseClicked(entity:Entity):void
		{
			remove();
		}
		
		private function handleUsernameClicked(entity:Entity):void
		{
			switchEntry("username");
		}
		
		private function handlePasswordClicked(entity:Entity):void
		{
			switchEntry("password");
		}

		private function hideOkButton(hide:Boolean = true):void
		{
			Display(_okButton.get(Display)).visible = !hide;
		}
		
		private function handleOkClicked(entity:Entity):void
		{
			showResult(LoginResult.LOADING_CHARACTER, false);

			var emptyUsername:Boolean = DataUtils.isNull(_usernameEntryText.text) || _usernameEntryText.text.toLowerCase() == "username";
			var emptyPassword:Boolean = DataUtils.isNull(_passwordEntryText.text) || _passwordEntryText.text.toLowerCase() == "password";
			
			if(emptyUsername || emptyPassword)
			{
				if(emptyUsername)
				{
					showResult(LoginResult.USERNAME_EMPTY);
				}
				else
				{
					showResult(LoginResult.PASSWORD_EMPTY);
				}
			}
			else
			{
				if(!checkBadUsername(_usernameEntryText.text)) 
				{
					if(!checkBadLogin(_usernameEntryText.text, _passwordEntryText.text)) 
					{
						var request:DataStoreRequest = PopDataStoreRequest.loginRequest();
						request.requestData = new URLVariables();
						request.requestData.login = _usernameEntryText.text;
						//Passwords are not case sensitive, and are LOWERCASED for encryption.
						request.requestData.pass_hash = MD5.hash(_passwordEntryText.text.toLowerCase());
						shellApi.siteProxy.retrieve(request, onLogin);
					}
					else
					{
						showDelayedResult(LoginResult.PASSWORD_INVALID);
					}
				}
				else
				{
					showDelayedResult(LoginResult.USERNAME_INVALID);
				}
			}
		}
		
		private function showDelayedResult(message:String):void
		{
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, Command.create(showResult, message)));
		}
		
		private function onLogin(response:PopResponse):void 
		{
			if(super.removalPending)
			{
				return;
			}
			
			var message:String;
			var loginError:Boolean = false;
			
			if (response.data == null || response.data.answer != LoginResult.ANSWER_OK || response.error || !response.data.hasOwnProperty("json")) 
			{
				message = LoginResult.ERROR_LOGIN;
				
				// handle specific errors.  If the user name or password is bad store it so we don't bother sending it to the
				//  server again if it hasn't changed (ex : spamming the 'ok' button with a bad login).
				if(response.data != null)
				{
					if(response.data.answer == LoginResult.ANSWER_WRONG_PASSWORD)
					{
						addBadLogin(_usernameEntryText.text, _passwordEntryText.text);
						message = LoginResult.PASSWORD_INVALID;
					}
					else if(response.data.answer == LoginResult.ANSWER_NO_USER)
					{
						addBadUsername(_usernameEntryText.text);
						message = LoginResult.USERNAME_INVALID;
					}
				}
				else if(response.status == GatewayConstants.AMFPHP_PROBLEM)
				{
					message = LoginResult.NO_NETWORK;
				}
				
				loginError = true;
			}
			else
			{
				var data:Object = JSON.parse(response.data.json);
				
				var login:String = String(data.login);
				
				var exists:Boolean = false;
				for each(var profile:ProfileData in shellApi.profileManager.profiles)
				{
					if(profile.login == login)
					{
						exists = true;
						break;
					}
				}
				
				if(exists)
				{
					loginError = true;
					message = LoginResult.LOGIN_EXISTS +  " for " + data.firstname + " " + data.lastname + ".";
				}
				else
				{
					message = LoginResult.LOGIN_SUCCEEDED +  " for " + data.firstname + " " + data.lastname + ".";
					
					shellApi.profileManager.updateLogin(shellApi.profileManager.active.login, login);
					shellApi.profileManager.active.pass_hash = data.pass_hash;
					
					var gender:String = String(data.look).split(",")[0] == "1" ? SkinUtils.GENDER_MALE : SkinUtils.GENDER_FEMALE;
					shellApi.profileManager.active.gender = gender;
					
					var loginData:LoginData = new LoginData();
					loginData.look = data.look;
					loginData.firstName = data.firstname;
					loginData.lastName = data.lastname;
					
					this.loggedIn.dispatch(loginData);
				}
			}
			
			showResult(message, loginError);
		}
		
		private function showResult(message:String, enableOk:Boolean = true):void
		{
			_display.result.text = message;
			hideOkButton(!enableOk);
		}

		private function switchEntry(type:String):void
		{
			var clip:MovieClip;
			var oldClip:MovieClip;
			
			if(type == "password")
			{
				clip = _passwordEntry;
				oldClip = _usernameEntry;
				_activeText = _passwordEntryText;
			}
			else
			{
				clip = _usernameEntry;
				oldClip = _passwordEntry;
				_activeText = _usernameEntryText;
			}
			
			_activeText.text = "";
			
			clip.gotoAndStop("on");
			oldClip.gotoAndStop("off");
			/*
			if(!_keyboard.isOpened)
			{
				_keyboard.open();
			}
			*/
		}
		
		/**
		 * Creates and open a KeyboardPopup
		 */
		/*
		private function createKeyboard():void
		{
			var keyboard:KeyboardPopup = new KeyboardPopup(super.groupContainer);
			keyboard.pauseParent = false;
			
			keyboard.config( null, null, false, false, false, false );
			//keyboard.groupPrefix = super.groupPrefix + "keyboard/";
			keyboard.groupPrefix = "ui/keyboard/";
			keyboard.keyboardType = KeyboardCreator.KEYBOARD_TEXT;
			keyboard.textFormat = new TextFormat("CreativeBlock BB", 24, 0xFFFFFF);
			keyboard.bufferRatio = .1;
			//keyboard.init();
			keyboard.keyInput.add( onKeyInput );
			
			// delay creating transitions until assets have loaded, as the transition relies on the asset dimensions for positioning information.
			keyboard.ready.addOnce( Command.create( onKeyboardLoaded, keyboard ) );	
			super.addChildGroup(keyboard);
			
			_keyboard = keyboard;
		}
		
		private function onKeyboardLoaded( obj:*, popup:Popup ):void
		{

			var transitionData:TransitionData = new TransitionData();
			transitionData.init( 0, super.shellApi.viewportHeight, 0, super.shellApi.viewportHeight - MovieClip(popup.screen).height*.85, Bounce.easeOut )
			popup.transitionIn = transitionData;
			popup.transitionOut = transitionData.duplicateSwitch( Strong.easeOut );
			//popup.open();
		}
		
		// pass inputs from keyboard to textdisplay, test input for scene progression
		public function onKeyInput( value:String ):void
		{	
			if(value == "delete")
			{
				if(_activeText.text.length > 0)
				{
					_activeText.text = _activeText.text.slice(0, _activeText.text.length - 1);
				}
			}
			else if(value == "enter")
			{
				_keyboard.hide();
			}
			else
			{
				_activeText.text = _activeText.text + value;
			}
			
		}
		*/
		
		private function addBadLogin(username:String, pass:String):void
		{
			if(!checkBadLogin(username, pass)) 
			{
				_badLogins.push( { username : username, pass : pass } );
			}
		}
		
		private function addBadUsername(username:String):void
		{
			if (!checkBadUsername(username)) 
			{
				_badUsernames.push(username);
			}
		}
		
		private function checkBadLogin(username:String, pass:String):Boolean
		{
			for(var n:Number = 0; n < _badLogins.length; n++) 
			{
				var nextLogin:Object = _badLogins[n];
				
				if (nextLogin.username == username) 
				{
					if (nextLogin.pass == pass) 
					{
						return true;
					}
				}
			}
			
			return false;
		}
		
		private function checkBadUsername(username:String):Boolean
		{	
			for(var n:Number = 0; n < _badUsernames.length; n++) 
			{		
				if(_badUsernames[n] == username) 
				{
					return true;
				}
			}
			
			return false;
		}
		
		public var loggedIn:Signal = new Signal(LoginData);
		private var _badUsernames:Vector.<String>;
		private var _badLogins:Vector.<Object>;
		private var _display:MovieClip;
		private var _tween:Tween;
		private var _usernameEntry:MovieClip;
		private var _passwordEntry:MovieClip;
		private var _usernameEntryText:TextField;
		private var _passwordEntryText:TextField;
		private var _activeText:TextField;
		private var _okButton:Entity;
		//private var _keyboard:KeyboardPopup;
		public static var GROUP_ID:String = "loginGroup";
	}
}