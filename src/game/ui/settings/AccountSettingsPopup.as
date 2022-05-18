package game.ui.settings
{	
	import com.adobe.crypto.MD5;
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	
	import as3reflect.Field;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.util.Command;
	
	import game.creators.ui.ButtonCreator;
	import game.data.ui.ButtonSpec;
	import game.managers.ProfileManager;
	import game.ui.hud.Hud;
	import game.ui.hud.HudPopBrowser;
	import game.ui.popup.MembershipPopup;
	import game.ui.popup.Popup;
	import game.ui.settings.SettingsPopup;
	import game.util.DataUtils;
	import game.util.DisplayPositionUtils;
	import game.util.DisplayPositions;
	import game.util.InputFieldUtil;
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;
	import game.util.SceneUtil;
	
	/**
	 * Presents an Accounts Settings Popup that shows current membership data and controls for changing password.
	 * 
	 * @author Rick Hocker
	 */
	public class AccountSettingsPopup extends Popup
	{
		public function AccountSettingsPopup(container:DisplayObjectContainer = null) 
		{
			super(container);
		}
		
		public override function init(container:DisplayObjectContainer = null):void 
		{
			this.groupPrefix 		= "ui/settings/";
			this.screenAsset 		= "accountSettings.swf";
			this.id = GROUP_ID;
			
			super.init(container);
			this.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			// position back button at top left
			_backButton = loadBackButton();
			
			// position close button at top right
			this.loadCloseButton(DisplayPositions.TOP_RIGHT, 0, 0, false, this.screen);
			
			// center screen
			this.screen.x = this.shellApi.viewportWidth * 0.5 - this.screen.width * 0.5;
			this.screen.y = this.shellApi.viewportHeight * 0.5 - this.screen.height * 0.5;		
			
			// update user name
			this.screen["userName"].text = this.shellApi.profileManager.active.login;
			
			var inputFields:Dictionary = new Dictionary();
			inputFields["oldPassword"] = "_passwordText";
			inputFields["newPassword"] = "_newPasswordText";
			inputFields["repeatPassword"] = "_repeatPasswordText";
			inputFields["parentEmail"] = "_parentEmailText";
			_fields = ["oldPassword","newPassword","repeatPassword","parentEmail"];
			for(var field:String in inputFields)
			{
				var tf:TextField = this.screen[field];
				InputFieldUtil.setUpFieldToScroll(tf, shellApi);
				tf.addEventListener(KeyboardEvent.KEY_DOWN, checkPressedEnter);
				var refName:String = inputFields[field];
				this[refName] = tf;
			}
			// get text and panels
			_passwordText = this.screen["oldPassword"];
			_newPasswordText = this.screen["newPassword"];
			_repeatPasswordText = this.screen["repeatPassword"];
			_parentEmailText = this.screen["parentEmail"];
			
			_emailMessageText = this.screen["emailMessage"];			
			_outputPanel = this.screen["output_message"];
			_cancelPanel = this.screen["cancel_confirm"];
			_outputText = _outputPanel["output"];
			
			// update buttons
			_authorizeButton = ButtonCreator.createButtonEntity(this.screen["authorizeButton"], this, this.onAuthorizeClicked);
			_emailButton = ButtonCreator.createButtonEntity(this.screen["emailButton"], this, this.onEmailClicked);
			//_cancelButton = ButtonCreator.createButtonEntity(this.screen["cancelButton"], this, this.onCancelClicked);
			//_buyButton = ButtonCreator.createButtonEntity(this.screen["buyButton"], this, this.onBuyClicked);
			this.screen["renewButton"].visible = false;
			this.screen["cancelButton"].visible = false;
			this.screen["buyButton"].visible = false;
			//_renewButton = ButtonCreator.createButtonEntity(this.screen["renewButton"], this, this.onBuyClicked);
			_cancelConfirmYesButton = ButtonCreator.createButtonEntity(_cancelPanel["yesButton"], this, this.cancelMembership);
			_cancelConfirmNoButton = ButtonCreator.createButtonEntity(_cancelPanel["noButton"], this, this.closeCancelPanel);
			
			// hide buttons and panels
			//_cancelButton.get(Display).visible = false;
			//_buyButton.get(Display).visible = false;
			//_renewButton.get(Display).visible = false;
			_cancelPanel.visible = false;
			_outputPanel.visible = false;
			
			// add event listeners to text fields
			_parentEmailText.addEventListener(Event.CHANGE, clearEmailText);
			_passwordText.addEventListener(Event.CHANGE, clearPasswordText);
			_newPasswordText.addEventListener(Event.CHANGE, clearPasswordText);
			_repeatPasswordText.addEventListener(Event.CHANGE, clearPasswordText);
			
			// grab data from server
			checkParentEmailStatus();
			initMemberData();		
		}
		
		protected function checkPressedEnter(event:KeyboardEvent):void
		{
			var targetTF:TextField = event.currentTarget as TextField;
			
			if(event.keyCode == Keyboard.ENTER)
			{
				if(!DataUtils.validString(targetTF.text))
					return;
				
				var isEmail:Boolean = targetTF.name == "parentEmail";
				
				var index:int = _fields.indexOf(targetTF.name);
				
				trace(targetTF.name + " : " + index + " / " + _fields.length);
				
				index++;
				if(index >= _fields.length)
					onEmailClicked(null);
				else if(index == _fields.length-1)
					onAuthorizeClicked(null);
				else
					this.screen.stage.focus = targetTF.parent[_fields[index]];
			}
		}
		
		/**
		 * load back button 
		 * @return 
		 */
		private function loadBackButton():Entity 
		{
			var buttonSpec:ButtonSpec = new ButtonSpec();
			buttonSpec.position = DisplayPositionUtils.getPosition( DisplayPositions.TOP_LEFT, this.screen.width, this.screen.height, 0, 0);
			buttonSpec.clickHandler = onBackClicked;
			buttonSpec.container = this.screen;
			return ButtonCreator.loadButtonEntityFromSpec( ButtonCreator.BACK_BUTTON, this, buttonSpec);
		}
		
		// BUTTON FUNCTIONS ////////////////////////////////
		
		/**
		 *Click back button to go back to settings popup 
		 * @param entity
		 */
		private function onBackClicked(entity:Entity):void
		{
			this.playClick();
			
			// close this popup
			this.close();
			
			// show settings popup
			var settings:Popup = new SettingsPopup();
			var hud:Hud = Hud(super.getGroupById(Hud.GROUP_ID));
			settings.popupRemoved.addOnce( hud.closeSettings );
			hud.addChildGroup(settings);
			settings.init( hud.groupContainer);	
			hud.enableHUDButtons(false, true);
		}
		
		/**
		 * Click authorize button to change password
		 * @param entity
		 */
		private function onAuthorizeClicked(entity:Entity):void
		{
			this.playClick();
			
			// hide authorize button
			_authorizeButton.get(Display).visible = false;
			
			// validate fields
			if (_passwordText.text == "")
				updatePasswordText("Enter your password, please.");
			else if (_newPasswordText.text == "")
				updatePasswordText("Enter your password, please.");
			else if (_newPasswordText.text.length < 5)
				updatePasswordText("Sorry, that password is too short.");
			else if (_repeatPasswordText.text == "")
				updatePasswordText("Retype your new password.");
			else if (_repeatPasswordText.text != _newPasswordText.text)
				updatePasswordText("Sorry, passwords do not match.");
			else if (_passwordText.text == _newPasswordText.text)
				updatePasswordText("Your new password matches the old one. Please choose a new password.");
			else if (isHere(_newPasswordText.text, this.shellApi.profileManager.active.login) || isHere(_newPasswordText.text, "password"))
				updatePasswordText("Your new password is too easy to guess – please pick another.");
			else 
			{
				// lock input
				SceneUtil.lockInput(this, true);
				
				// set up vars to send
				var loadVars:URLVariables = new URLVariables();
				loadVars.login = this.shellApi.profileManager.active.login;
				loadVars.pass_hash = MD5.hash(_passwordText.text.toLowerCase());
				var newPassword:String = _newPasswordText.text.toLowerCase();
				loadVars.pass_hash_new = MD5.hash(newPassword);
				// for pop 2.0 compatibility
				loadVars.new_password = newPassword;
				
				// get data
				serverRequest(shellApi.siteProxy.commData.changePasswordURL, loadVars, passwordChangeSuccess, passwordChangeError);
			}		
		}
		
		/**
		 * Click email button to update parent email address
		 * @param entity
		 */
		private function onEmailClicked(entity:Entity):void
		{
			this.playClick();
			
			// if email button is not solid, then return
			if (_emailButton.get(Display).alpha != 1.0)
				return;
				
				// validate parent email field
			else if (_parentEmailText.text == "")
			{
				updateEmailText("Please enter a Parent Email Address.");
				return;
			}			
			else if (!checkEmailString(_parentEmailText.text))
			{
				updateEmailText("The Parent Email address is not valid.");
				return;
			}
				// if last email sent has changed
			else if (_lastParentEmailSent != _parentEmailText.text)
			{
				// dim button
				_emailButton.get(Display).alpha = 0.4;
				// save parent email text
				_lastParentEmailSent = _parentEmailText.text;
				
				// set up vars to send
				var loadVars:URLVariables = new URLVariables();
				loadVars.login = this.shellApi.profileManager.active.login;
				loadVars.pass_hash = this.shellApi.profileManager.active.pass_hash;
				loadVars.dbid = String(this.shellApi.profileManager.active.dbid);
				loadVars.parent_email = _lastParentEmailSent;
				loadVars.action = "insertParentEmail";
				
				// get data
				serverRequest(shellApi.siteProxy.commData.parentalEmailURL, loadVars, parentEmailSuccess, parentEmailError);
			}
			else
			{
				// if emails match, then clear email message
				trace("parent emails match");
				
				// if email message not already displayed
				if (!_waitingForEmailMessage)
				{
					// set flag to true
					_waitingForEmailMessage = true;
					// dim button
					_emailButton.get(Display).alpha = 0.4;
					// lock input
					SceneUtil.lockInput(this, true);
					
					// remember email message and clear field
					_savedEmailStatusMessage = _emailMessageText.text;
					_emailMessageText.text = "";
					// restore email message after delay
					SceneUtil.delay(this, EMAIL_MESSAGE_TIMEOUT, revealResetErrorMessage);
				}
			}
		}
		
		/**
		 * Click buy button and go to web page to buy membership 
		 * @param entity
		 */
		private function onBuyClicked(entity:Entity):void
		{
			this.playClick();
			
			var popup:MembershipPopup = HudPopBrowser.buyMembership(shellApi);
			if(popup)
			{
				popup.removed.addOnce(initMemberData);
			}
		}
		
		/**
		 * Click cancel button and cancel membership 
		 * @param entity
		 */
		private function onCancelClicked(entity:Entity):void
		{
			this.playClick();
			
			if(_source == "iap")
			{
				var path:String = shellApi.siteProxy.secureHost + "/about/help.html#membership";
				
				navigateToURL(new URLRequest(path), '_blank');
			}
			else
			{
				// hide cancel button and panel
				_cancelButton.get(Display).visible = false;
				_cancelPanel.visible = true;
			}
		}
		
		// GET MEMBER DATA //////////////////////////////////////
		
		/**
		 * Get membership data when popup is loaded 
		 */
		private function initMemberData(...args):void
		{
			// set up vars to send
			var loadVars:URLVariables = new URLVariables();
			loadVars.login = this.shellApi.profileManager.active.login;
			loadVars.pass_hash = this.shellApi.profileManager.active.pass_hash;
			loadVars.dbid = String(this.shellApi.profileManager.active.dbid);
			
			// get data
			serverRequest(shellApi.siteProxy.commData.memberStatusURL, loadVars, memberDataSuccess, memberDataError);
		}
		
		/**
		 * When receive membership data 
		 * @param e
		 */
		private function memberDataSuccess(e:Event):void
		{
			URLLoader(e.currentTarget).removeEventListener(Event.COMPLETE, memberDataSuccess);
			URLLoader(e.currentTarget).removeEventListener(IOErrorEvent.IO_ERROR, memberDataError);
			
			trace("Membership data success: " + e.currentTarget.data);
			
			// if popup is already closed then return
			if (this.screen == null)
				return;
			
			// convert to variables
			var loadVars:URLVariables = new URLVariables(e.currentTarget.data);
			var memstatus:String = loadVars["mem_status"];
			var memdate:String = loadVars["mem_expire_date"];
			var renewdate:String = loadVars.renewdate;
			_source = loadVars["mem_source"];
			
			trace("source: " + _source);
			
			// get text fields
			var memStatusText:TextField = this.screen["memberStatus"];
			var renewMessText:TextField = this.screen["renewMessage"];
			var renewDateText:TextField = this.screen["renewDate"];
			
			var showBuyButton:Boolean = !(!AppConfig.iapOn && PlatformUtils.isMobileOS)
			
			switch(memstatus)
			{
				case "expired":
					memStatusText.text = "Cancelled";
					renewMessText.text = "Expired On";
					renewDateText.text = formatDate(memdate);
					//_buyButton.get(Display).visible = showBuyButton;
					break;
				case "active-renew":
					memStatusText.text = "Active";
					renewMessText.text = "Will Renew On";
					renewDateText.text = formatDate(renewdate?renewdate:memdate);
					//_cancelButton.get(Display).visible = true;
					break;
				case "active-pending":
					memStatusText.text = "Active";
					renewMessText.text = "Will Renew On";
					renewDateText.text = formatDate(renewdate);
					_outputPanel.visible = true;
					_outputText.text = "Please check back in 24 hrs to cancel";
					break;
				case "active-norenew":
					memStatusText.text = "Active";
					renewMessText.text = "Expires On";
					renewDateText.text = formatDate(memdate);
					//_renewButton.get(Display).visible = showBuyButton;
					break;
				case "notmember":
					memStatusText.text = "Nonmember";
					renewMessText.text = "";
					renewDateText.text = "";
					//_buyButton.get(Display).visible = showBuyButton;
					break;
				default:
					memStatusText.text = memstatus;
					break;
			}
		}
		
		/**
		 * When membership data fails 
		 * @param e
		 */
		private function memberDataError(e:IOErrorEvent):void
		{
			URLLoader(e.currentTarget).removeEventListener(Event.COMPLETE, memberDataSuccess);
			URLLoader(e.currentTarget).removeEventListener(IOErrorEvent.IO_ERROR, memberDataError);
			
			trace("Membership data retrieval failure");
		}
		
		// PARENT EMAIL STATUS /////////////////////////////////////
		
		/**
		 * Check status of parent email
		 */
		private function checkParentEmailStatus():void
		{	
			// set up vars to send
			var loadVars:URLVariables = new URLVariables();
			loadVars.login = this.shellApi.profileManager.active.login;
			loadVars.pass_hash = this.shellApi.profileManager.active.pass_hash;
			loadVars.dbid = String(this.shellApi.profileManager.active.dbid);
			loadVars.parent_email = _parentEmailText.text;
			loadVars.action = "hasParentEmail";
			
			// get data
			serverRequest(shellApi.siteProxy.commData.parentalEmailURL, loadVars, parentEmailStatusSuccess, parentEmailStatusError);
		}
		
		/**
		 * When receive parent email status data
		 * @param e
		 */
		private function parentEmailStatusSuccess(e:Event):void
		{
			URLLoader(e.currentTarget).removeEventListener(Event.COMPLETE, parentEmailStatusSuccess);
			URLLoader(e.currentTarget).removeEventListener(IOErrorEvent.IO_ERROR, parentEmailStatusError);
			
			trace("Parent email status data: " + e.currentTarget.data);
			
			// if popup is already closed then return
			if (this.screen == null)
				return;
			
			// remove leading & if found
			if (e.currentTarget.data.charAt(0) == "&")
				e.currentTarget.data = e.currentTarget.data.substr(1);
			
			// convert to variables
			try
			{
				var loadVars:URLVariables = new URLVariables(String(e.currentTarget.data));
				
				// if success
				if (loadVars.answer == "ok")
				{
					var response:String = loadVars.has_parent_email;
					if(response == "Verified" || response == "Expired" || response == "Pending")
					{
						// update email message text
						_emailMessageText.text = "Parent Email Request " + loadVars.has_parent_email + ".";
						// populate parent email field
						_parentEmailText.text = loadVars.parent_email;
					}
				}
				else
				{
					_emailMessageText.text = "Database Error, Please try again later.";
				}
			} 
			catch(error:Error) 
			{
				_emailMessageText.text = "Database Error, Please try again later.";
			}
		}
		
		private function parentEmailStatusError(e:IOErrorEvent):void
		{
			URLLoader(e.currentTarget).removeEventListener(Event.COMPLETE, parentEmailStatusSuccess);
			URLLoader(e.currentTarget).removeEventListener(IOErrorEvent.IO_ERROR, parentEmailStatusError);
			
			// if popup still exists
			if (this.screen)
				_emailMessageText.text = "Parent email status failed";
		}
		
		// PASSWORD CHANGES //////////////////////////////////////
		
		/**
		 * When receive password change data
		 * @param e
		 */
		private function passwordChangeSuccess(e:Event):void
		{
			URLLoader(e.currentTarget).removeEventListener(Event.COMPLETE, passwordChangeSuccess);
			URLLoader(e.currentTarget).removeEventListener(IOErrorEvent.IO_ERROR, passwordChangeError);
			
			trace("Password change data: " + e.currentTarget.data);
			
			// convert to variables
			var loadVars:URLVariables = new URLVariables(e.currentTarget.data);
			
			// if success
			if (loadVars.answer == "ok" || loadVars.answer == "success")
			{
				var profileManager:ProfileManager = shellApi.profileManager;
				var pass_hash:String = MD5.hash(_newPasswordText.text.toLowerCase());
				// tracking
				this.shellApi.track(STORE_EVENT, CHANGE_PASSWORD_COMPLETED);
				
				// save new password
				profileManager.active.pass_hash = pass_hash;
				profileManager.save();
				
				var lso:SharedObject = ProxyUtils.as2lso;				
				lso.data.password = pass_hash;
				lso.flush();
				
				updatePasswordText("Your password successfully changed.");
			}
			else
			{
				// if failure
				// show authorize button
				showAuthButton();
				
				// check error message and display
				var error:String = loadVars.answer;
				if (error == "wrongpass" || error.charAt(0) == "w")
					updatePasswordText("Sorry, your password is incorrect.");
				else if (error == "nologin" || error.charAt(0) == "n")
					updatePasswordText("Enter your name, please.");
				else
					updatePasswordText("An error while connecting to database occurred. Try a bit later.");
			}
			//unlock input
			SceneUtil.lockInput(this, false);
		}
		
		/**
		 * when password change fails 
		 * @param e
		 */
		private function passwordChangeError(e:IOErrorEvent):void
		{
			URLLoader(e.currentTarget).removeEventListener(Event.COMPLETE, passwordChangeSuccess);
			URLLoader(e.currentTarget).removeEventListener(IOErrorEvent.IO_ERROR, passwordChangeError);
			
			//unlock input
			SceneUtil.lockInput(this, false);		
			// show authorize button
			showAuthButton();
			// display message
			updatePasswordText("Password change failed.");
		}
		
		/**
		 * clear password message text when typing into fields
		 * @param e
		 */
		private function clearPasswordText(e:Event):void
		{
			// show authorize button
			showAuthButton();
			updatePasswordText("");			
		}
		
		/**
		 * Update text in password message field 
		 * @param message
		 */
		private function updatePasswordText(message:String):void
		{
			if (this.screen)
				this.screen["passwordMessage"].text = message;
		}
		
		// PARENT EMAIL //////////////////////////////////////////
		
		/**
		 * When receive parent email data
		 * @param e
		 */
		private function parentEmailSuccess(e:Event):void
		{
			URLLoader(e.currentTarget).removeEventListener(Event.COMPLETE, parentEmailSuccess);
			URLLoader(e.currentTarget).removeEventListener(IOErrorEvent.IO_ERROR, parentEmailError);
			
			trace("Parent email data: " + e.currentTarget.data);
			
			// undim email button
			undimEmailButton();
			
			// convert to variables
			var loadVars:URLVariables = new URLVariables(e.currentTarget.data);
			
			// if success
			if (loadVars.answer == "ok")
			{	
				trace("Parent email accepted!");
				
				// save parent email to lso
				var lso:SharedObject = ProxyUtils.as2lso;				
				lso.data.parentEmail = _parentEmailText.text;
				lso.flush();
				
				// check parent email status (expect status to change)
				checkParentEmailStatus();
			}
			else
			{
				// if error
				updateEmailText("We were unable to save this email address. Please try again.");
			}
		}
		
		/**
		 * if error changing parent email
		 * @param e
		 */
		private function parentEmailError(e:IOErrorEvent):void
		{
			URLLoader(e.currentTarget).removeEventListener(Event.COMPLETE, parentEmailSuccess);
			URLLoader(e.currentTarget).removeEventListener(IOErrorEvent.IO_ERROR, parentEmailError);
			
			// undim email button
			undimEmailButton();
			updateEmailText("Parent email request failed.");
		}
		
		/**
		 * Clear email message text when typing
		 * @param e
		 */
		private function clearEmailText(e:Event):void
		{
			updateEmailText("");
		}
		
		/**
		 * Update email message text with new text 
		 * @param message
		 */
		private function updateEmailText(message:String):void
		{
			if (this.screen)
				_emailMessageText.text = message;
		}
		
		/**
		 * Restore email message after timeout 
		 */
		private function revealResetErrorMessage():void
		{
			// undim email button
			undimEmailButton();
			// clear flag
			_waitingForEmailMessage = false;
			// unlock input
			SceneUtil.lockInput(this, false);
			// update email text
			updateEmailText(_savedEmailStatusMessage);
		}
		
		// CANCEL FUNCTIONS ///////////////////////////////////////	
		
		/**
		 * Cancel membership 
		 * @param entity
		 */
		private function cancelMembership(entity:Entity):void
		{
			this.playClick();
			
			// hide cancel panel and show output panel
			_cancelPanel.visible = false;
			_outputPanel.visible = true;
			
			// get password entered
			var passConfirm:String = _cancelPanel["passwordConfirm"].text;
			
			// check if empty string
			if (passConfirm == "")
			{
				waitHideOutputMessage("You must re-enter your password");
				return;
			}
			_outputText.text = "processing...";
			
			// set up vars to send
			var loadVars:URLVariables = new URLVariables();
			loadVars.login = this.shellApi.profileManager.active.login;
			loadVars.pass_hash = MD5.hash(passConfirm.toLowerCase());
			
			// send data
			serverRequest(shellApi.siteProxy.commData.cancelMembership, loadVars, cancelSuccess, cancelError);
		}
		
		/**
		 * When receive cancellation data 
		 * @param e
		 */
		private function cancelSuccess(e:Event):void
		{
			URLLoader(e.currentTarget).removeEventListener(Event.COMPLETE, cancelSuccess);
			URLLoader(e.currentTarget).removeEventListener(IOErrorEvent.IO_ERROR, cancelError);
			
			trace("Cancel data: " + e.currentTarget.data);
			
			// convert to variables
			var loadVars:URLVariables = new URLVariables(e.currentTarget.data);
			
			// if error message
			if (loadVars.message)
			{
				// show timed error message
				waitHideOutputMessage("ERROR: " + loadVars.message);
			}
			else
			{
				// if success
				if (this.screen)
				{
					_outputText.text = "Your membership auto-renewal is successfully cancelled";
					
					// update screen and remove cancel button
					_cancelButton.get(Display).visible = false;
					this.screen["memberStatus"].text = "Cancelled";
					this.screen["renewMessage"].text = "Expires On";
				}
			}
		}
		
		/**
		 * When cancellation fails 
		 * @param e
		 * 
		 */
		private function cancelError(e:IOErrorEvent):void
		{
			URLLoader(e.currentTarget).removeEventListener(Event.COMPLETE, cancelSuccess);
			URLLoader(e.currentTarget).removeEventListener(IOErrorEvent.IO_ERROR, cancelError);
			
			waitHideOutputMessage("Renewal cancellation failed");
		}
		
		/**
		 * Close cancel panel 
		 * @param entity
		 */
		private function closeCancelPanel(entity:Entity):void
		{
			this.playClick();
			
			_cancelPanel.visible = false;
		}
		
		/**
		 * Show output message and wait 4 seconds before hiding message
		 * @param message
		 */
		private function waitHideOutputMessage(message:String):void
		{
			if (this.screen)
			{
				_outputText.text = message;
				// remove after 4 seconds
				SceneUtil.delay(this, OUTPUT_MESSAGE_TIMEOUT, hideOutputMessage);
			}
		}
		
		/**
		 * Hide output message 
		 */
		private function hideOutputMessage():void
		{
			if (this.screen)
				_outputPanel.visible = false;
		}
		
		// HELPER FUNCTIONS ////////////////////////////////////////
		
		/**
		 * Setup server request 
		 * @param path
		 * @param loadVars
		 * @param success function
		 * @param error function
		 */
		private function serverRequest(path:String, loadVars:URLVariables, success:Function, error:Function):void
		{
			// set up url with secure host
			var request:URLRequest = new URLRequest(this.shellApi.siteProxy.secureHost + path);
			var urlLoader:URLLoader = new URLLoader();
			
			// add listeners
			urlLoader.addEventListener(Event.COMPLETE, success);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, error);
			
			// get data
			request.method = URLRequestMethod.POST;
			request.data = loadVars;			
			urlLoader.load(request);
		}
		
		/**
		 * Show authorize button 
		 */
		private function showAuthButton():void
		{
			if (this.screen)
				_authorizeButton.get(Display).visible = true;
		}
		
		/**
		 * Undim email button
		 */
		private function undimEmailButton():void
		{
			if (this.screen)
				_emailButton.get(Display).alpha = 1.0;
		}
		
		/**
		 * Test whether a string contains another string, including reverse order
		 * @param where
		 * @param what
		 * @return Boolean
		 */
		private function isHere(where:String, what:String):Boolean
		{
			// trim off leading and trailing numbers
			what = getTrimmedString(what);
			// if found in test string or found in reverse, then return true
			if (where.indexOf(what) != -1 || where.indexOf(what.split("").reverse().join("")) != -1)
				return true;
			return false;
		}
		
		/**
		 * Get string cleaned from any leading or trailing numbers 
		 * @param str
		 * @return String
		 */
		private function getTrimmedString(str:String):String
		{
			// strip off numbers from end
			var i:int = str.length;
			while (str.charCodeAt(i-1)>47 && str.charCodeAt(i-1)<58 && i>0) i--;
			str = str.substr(0,i);
			
			// strip off numbers from beginning
			var j:int = 0;
			while (str.charCodeAt(j)>47 && str.charCodeAt(j)<58 && j<=str.length) j++;
			return str.substr(j, str.length - j);
		}
		
		/**
		 * Validate email string for parent's email 
		 * @param email
		 * @return Boolean
		 */
		private function checkEmailString(email:String):Boolean
		{
			var emailPattern_str:String = '^[^@ ]+\\@[-\\d\\w]+(\\.[-\\d\\w]+)+$';
			var flags:String = 'gim'; // global, case Insensitive, multiline			
			var email_re:RegExp = new RegExp(emailPattern_str, flags);			
			return(email_re.test(email));
		}
		
		/**
		 * Format date string into more pleasing appearance 
		 * @param dateString
		 * @return String
		 */
		private function formatDate(dateString:String):String
		{
			var months:Array = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
			var dateTime:Array = dateString.split(" ");
			var dateArr:Array = dateTime[0].split("-");
			var output:String = months[parseInt(dateArr[1])-1];
			output += " " + dateArr[2];
			output += ", " + dateArr[0];
			return output;
		}
		
		public static const GROUP_ID:String = "account_settings_panel";
		
		// tracking constants
		private static const STORE_EVENT:String = "StoreEvent";
		private static const CHANGE_PASSWORD_COMPLETED:String = "ChangePasswordCompleted";		
		
		// timeout constants
		private const EMAIL_MESSAGE_TIMEOUT:Number = 1.1;
		private const OUTPUT_MESSAGE_TIMEOUT:Number = 4;
		
		// text fields
		private var _passwordText:TextField;
		private var _newPasswordText:TextField;
		private var _repeatPasswordText:TextField;
		private var _parentEmailText:TextField;
		private var _emailMessageText:TextField;
		private var _outputText:TextField;
		
		// buttons
		private var _authorizeButton:Entity;
		private var _emailButton:Entity;
		private var _cancelButton:Entity;
		private var _buyButton:Entity;
		private var _renewButton:Entity;
		private var _cancelConfirmYesButton:Entity;
		private var _cancelConfirmNoButton:Entity;
		private var _backButton:Entity;
		
		// panels and text fields
		private var _outputPanel:MovieClip;
		private var _cancelPanel:MovieClip;
		
		private var _lastParentEmailSent:String;
		private var _savedEmailStatusMessage:String = "";
		private var _waitingForEmailMessage:Boolean = false;
		private var _source:String;
		
		private var _fields:Array;
	}
}