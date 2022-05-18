package game.ui.settings
{
	import com.adobe.crypto.MD5;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.KeyboardEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	
	import game.creators.ui.ButtonCreator;
	import game.data.comm.PopResponse;
	import game.data.profile.ProfileData;
	import game.proxy.DataStoreRequest;
	import game.proxy.IDataStore2;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	import game.util.TextUtils;
	
	public class AccountSettings extends Popup
	{
		public function AccountSettings(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			groupPrefix = "ui/settings/";
			screenAsset = "accountSettings.swf";
			super.init(container);
			load();
		}
		
		override public function load():void
		{
			super.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			playerProfile = shellApi.profileManager.active;
			
			var content:MovieClip = screen.content;
			refreshAll(content);
			content.tabChildren = true;
			oldPass.tabIndex = 1;
			oldPass.addEventListener(KeyboardEvent.KEY_UP, updatePassWarning);
			newPass.tabIndex = 2;
			newPass.addEventListener(KeyboardEvent.KEY_UP, updatePassWarning);
			newPassRe.tabIndex = 3;
			newPassRe.addEventListener(KeyboardEvent.KEY_UP, updatePassWarning);
			
			(shellApi.siteProxy as IDataStore2).call(DataStoreRequest.parentalEmailStatusRequest(), checkParentEmail);
			
			loadCloseButton();// just so people can close it
		}
		
		private function checkParentEmail(popResponse:PopResponse):void
		{
			if(popResponse.succeeded)
			{
				if(popResponse.data.answer == "ok")
				{
					lastEmailStatus = popResponse.data.has_parent_email;
					lastEmail = popResponse.data.parent_email;
					parentEmail.text = lastEmail;
					emailError.text = lastEmailStatus;
				}
			}
		}
		
		private var lastEmailStatus:String = "expired";
		private var lastEmail:String = "foo.bar@gmail.com";
		private var testPassword:String = "asdfasdf";
		
		private var oldPass:TextField;
		private var newPass:TextField;
		private var newPassRe:TextField;
		private var passwordError:TextField;
		private var parentEmail:TextField;
		private var emailError:TextField;
		private var memberStatus:TextField;
		private var userName:TextField;
		private var renewMessage:TextField;
		private var renewDate:TextField;
		private var output:TextField;
		private var passConfirm:TextField;
		
		private var playerProfile:ProfileData;
		
		private var textChecks:Array = ["oldPass", "newPass", "newPassRe", "passwordError", "parentEmail", "emailError", "memberStatus", "userName", "renewMessage", "renewDate", "output", "passConfirm"];
		
		private function refreshAll(container:MovieClip):void
		{
			container.gotoAndStop(0);
			var disp:DisplayObject;
			var tf:TextField;
			var format:TextFormat;
			
			for(var i:int = 0; i < container.numChildren; ++i)
			{
				disp = container.getChildAt(i);
				if(disp is TextField)
				{
					var fontStartIndex:int = disp.name.indexOf("_");
					var font:String = "";
					if(fontStartIndex >= 0)
					{
						font = disp.name.substr(fontStartIndex + 1);
						font = font.replace("$", " ");
					}
					tf = TextUtils.refreshText(disp as TextField, font);
					if(tf.type != TextFieldType.INPUT)
						tf.autoSize = TextFieldAutoSize.RIGHT;
					if(fontStartIndex >= 0)
					{
						var tfName:String = tf.name.substr(0, fontStartIndex);
						if(textChecks.indexOf(tfName) >= 0)
						{
							this[tfName] = tf;
						}
					}
				}
				else if(disp is DisplayObjectContainer)
				{
					var clip:MovieClip = disp as MovieClip;
					refreshAll(clip);
					if(disp.name.indexOf("Btn") >=0)
					{
						var prefix:String = disp.name.substr(0, disp.name.indexOf("Btn"));
						var entity:Entity = ButtonCreator.createButtonEntity(disp as DisplayObjectContainer,this, this[prefix]).add(new Id(clip.name));
					}
				}
			}
		}
		
		private function updateEmailError(...args):void
		{
			if(parentEmail.text == "")
				emailError.text = "Please enter a Parent Email Address.";
			else
			{
				if(!checkEmailString(parentEmail.text))
					emailError.text = "The Parent Email address is not valid.";
				else
				{
					if(parentEmail.text == lastEmail)
					{
						//this should be the error, but until i know how to access the parent's last email
						//this will have to do
						trace("you already have this email set as your parent's email");
					}
					emailError.text = "";
				}
			}
		}
		
		private function checkEmailString(email:String):Boolean
		{
			var emailPattern_str:String = '^[^@ ]+\\@[-\\d\\w]+(\\.[-\\d\\w]+)+$';
			var flags:String = 'gim'; // global, case Insensitive, multiline
			
			var email_re:RegExp = new RegExp(emailPattern_str, flags);
			
			return(email_re.test(email));
		}
		
		private function updatePassWarning(e:KeyboardEvent = null):void
		{
			if(e)
			{
				EntityUtils.visible(getEntityById("authorizeBtn"));
				//dont want key strokes to update the warning or it would make fishing for the password easier
				return;
			}
			if(oldPass.text == "" || newPass.text == "")
				passwordError.text = "Enter your password, please.";
			else
			{
				if(MD5.hash(oldPass.text) != playerProfile.pass_hash)//there is a password variable, but that REALLY shouldn't be there
					passwordError.text = "Current password is incorrect. " + playerProfile.password + " != " + oldPass.text;
				else
				{
					if(newPass.text.length < 5)
						passwordError.text = "Sorry, that password is too short.";
					else
					{
						if(newPassRe.text == "")
							passwordError.text = "Retype your password.";
						else
						{
							if(newPass.text != newPassRe.text)
								passwordError.text = "Sorry, passwords do not match. " + newPass.text + " != " + newPassRe.text
							else
							{
								if(newPass.text == oldPass.text)
									passwordError.text = "Your new password matches the old one. Please choose a new password.";
								else
								{
									if(newPass.text.indexOf(playerProfile.login)>=0 || newPass.text.indexOf("password")>= 0)
										passwordError.text = "Your new password is too easy to guess. Please pick another.";
									else
									{
										passwordError.text = "";
									}
								}
							}
						}
					}
				}
			}
		}
		
		private function renew(entity:Entity):void
		{
			
		}
		
		private function cancel(entity:Entity):void
		{
			
		}
		
		private function buy(entity:Entity):void
		{
			
		}
		
		private function authorize(entity:Entity):void
		{
			EntityUtils.visible(entity, false);
			updatePassWarning();
			if(passwordError.text == "")
			{
				var request:DataStoreRequest = DataStoreRequest.passwordChangeStorageRequest(playerProfile.login, oldPass.text, newPass.text);
				
				(shellApi.siteProxy as IDataStore2).call(request, onPasswordeReset);
			}
		}
		
		private function onPasswordeReset(popResponse:PopResponse):void
		{
			if(!popResponse.succeeded)
			{
				if(popResponse.error)
					passwordError.text = String(popResponse.error);
				else
					passwordError.text = "Could not connect to server. Try again soon.";
			}
			else
			{
				passwordError.text = "You successfully changed your password!";
				oldPass.text = newPass.text = newPassRe.text = "";
			}
		}
		
		private function email(entity:Entity):void
		{
			updateEmailError();
			if(emailError.text == "")
			{
				var request:DataStoreRequest = DataStoreRequest.parentalEmailUpdateRequest(parentEmail.text);
				
				(shellApi.siteProxy as IDataStore2).call(request, onParentEmailSet);
			}
		}
		
		private function onParentEmailSet(popResponse:PopResponse):void
		{
			if(!popResponse.succeeded)
			{
				if(popResponse.error)
					emailError.text = String(popResponse.error);
				else
					emailError.text = "Could not connect to server. Try again soon.";
			}
			else
				emailError.text = "You successfully set your parents email!";
		}
		
		private function yes(entity:Entity):void
		{
			
		}
		
		private function no(entity:Entity):void
		{
			
		}
	}
}