package game.scenes.start.login.groups
{
	import com.adobe.crypto.MD5;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import engine.group.Group;
	
	import game.data.character.LookConverter;
	import game.data.profile.ProfileData;
	import game.managers.ProfileManager;
	import game.proxy.DataStoreProxyPop;
	import game.proxy.browser.DataStoreProxyPopBrowser;
	import game.ui.login.LoginResult;
	import game.util.DataUtils;
	import game.util.PlatformUtils;
	import game.util.SkinUtils;
	
	import org.osflash.signals.Signal;
	
	public class FillOutLoginProfile extends Group
	{
		private var userName:String;
		private var password:String;
		private var onComplete:Signal;
		private var autoEncode:Boolean = true;
		private var grantedAccess:Boolean = false;
		
		public function FillOutLoginProfile()
		{
			onComplete = new Signal(Boolean, String, Object);
		}
		
		public function login(userName:String, password:String, onComplete:Function, autoEncode:Boolean = true):void
		{
			this.userName = userName;
			this.password = password;
			if(shellApi.devTools && shellApi.devTools.console && autoEncode)
			{
				autoEncode = !shellApi.devTools.console.devLoginEnabled;
			}
			this.autoEncode = autoEncode;
			if(onComplete)
			{
				this.onComplete.addOnce(onComplete);
			}
			tryLogin();
		}
		
		private function tryLogin(...args):void
		{
			trace("try login");
			var postVars:URLVariables = new URLVariables();
			postVars.login = userName;
			//Passwords are not case sensitive, and are LOWERCASED for encryption.
			// adding a bool for auto encoding so devs can pass a hash directly
			postVars.pass_hash = autoEncode?MD5.hash(password.toLowerCase()):password;
			var url:String = super.shellApi.siteProxy.secureHost + "/login.php";
			
			var req:URLRequest = new URLRequest(url);
			req.method = URLRequestMethod.POST;
			req.data = postVars;
			var loader:URLLoader = new URLLoader(req);
			
			loader.addEventListener(Event.COMPLETE,check);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
			loader.load(req);
		}
		
		private function check(event:Event):void
		{
			trace("attemping to login with username: " + userName + " and password: " + password);
			(event.target as URLLoader).removeEventListener(Event.COMPLETE, check);
			(event.target as URLLoader).removeEventListener(IOErrorEvent.IO_ERROR, onError);
			
			var theResult:String = (event.target as URLLoader).data;
			var resultVars:URLVariables = new URLVariables((event.target as URLLoader).data);
			
			//shellApi.logWWW("POST result", theResult, JSON.stringify(resultVars));
			
			//for (var p:String in resultVars) 
			//{
				//shellApi.logWWW(p, '=', resultVars[p]);
			//}
			
			var success:Boolean = true;
			var message:String = resultVars.message;
			var jsonData:Object;
			var keyInfo:Object = null;
			
			if(resultVars == null || resultVars.answer != LoginResult.ANSWER_OK || !resultVars.hasOwnProperty("json"))
			{
				success = false;
				var answer:String = resultVars.answer;
				// if the result comes back with its own message, 
				// that means it could not access the xpop server.
				// if so, give yourself access and try again.
				trace(answer + " : " + shellApi.siteProxy.secureHost+shellApi.siteProxy.commData.grantMeAccess);
				if(answer == "logout" && !grantedAccess && shellApi.siteProxy.secureHost.indexOf("xpop") >= 0)
				{
					grantedAccess = true;
					var req:URLRequest = new URLRequest(shellApi.siteProxy.secureHost + shellApi.siteProxy.commData.grantMeAccess);
					req.method = URLRequestMethod.POST;
					var loader:URLLoader = new URLLoader(req);
					loader.load(req);
					loader.addEventListener(Event.COMPLETE,tryLogin);
					return;
				}
				else
				{
					switch(answer)
					{
						case LoginResult.ANSWER_WRONG_PASSWORD:
						{
							message = LoginResult.PASSWORD_INVALID;
							jsonData = JSON.parse(resultVars.json);
							
							keyInfo = getKeyInfo(jsonData);
							break;
						}
						case LoginResult.ANSWER_NO_USER:
						{
							message = LoginResult.USERNAME_INVALID;
							break;
						}
						default:
						{
							if(!DataUtils.validString(message))
								message = !shellApi.networkAvailable()?LoginResult.NETWORK_ERROR:LoginResult.ERROR_LOGIN;
							break;
						}
					}
				}
			}
			else
			{
				trace("login successful");
				trace(resultVars.json);
				
				jsonData = JSON.parse(resultVars.json);
				var profile:ProfileData = new ProfileData(jsonData.login);
				
				trace("---------got prev island " + jsonData.island);
				profile.previousIsland = jsonData.island;
				if(profile.previousIsland == "Early" && !PlatformUtils.inBrowser)
					profile.previousIsland = "Hub";
				
				profile.avatarFirstName = jsonData.firstname;
				profile.avatarLastName = jsonData.lastname;
				profile.age = jsonData.age;
				profile.gender = jsonData.gender == 0 || jsonData.gender == "F" ? SkinUtils.GENDER_FEMALE : SkinUtils.GENDER_MALE;
				
				profile.profileComplete = true;
				profile.isGuest = false;
				profile.pass_hash = autoEncode?MD5.hash(password.toLowerCase()):password;
				profile.dbid = jsonData.dbid;
				
				var games:Array = String(jsonData.scores).split("*");
				for(var i:int = 0; i < games.length; i++)
				{
					var gameInfo:Array = String(games[i]).split(";");
					var gameName:String = gameInfo[0];
					var score:int = gameInfo[1];
					var wins:int = gameInfo[2];
					var losses:int = gameInfo[3];
					profile.scores[gameName] = {score:score, wins:wins, losses:losses};
				}
				
				var lookConverter:LookConverter = new LookConverter();
				trace("update look: " + jsonData.look);
				profile.look = lookConverter.playerLookFromLookString(shellApi, jsonData.look, null, (shellApi.siteProxy as DataStoreProxyPop).partKeyLibrary);
				
				shellApi.profileManager.add(profile, true);
				shellApi.profileManager.setDialogSpeedByAge();
				ProfileManager.fillOutUserData(profile, jsonData);
				shellApi.profileManager.updateCredits();
				
				keyInfo = getKeyInfo(jsonData);
			}
			trace("login message: " + message);
			onComplete.dispatch(success, message, keyInfo);
		}
		
		private function getKeyInfo(jsonData:Object):Object
		{
			var keyInfo:Object = new Object();
			keyInfo.dbid = jsonData.dbid;
			keyInfo.login = userName;
			keyInfo.parentEmailStatus = jsonData.has_parent_email;
			keyInfo.parentEmail = jsonData.parent_email;
			return keyInfo;
		}
		
		private function onError(e:IOErrorEvent):void {
			shellApi.logWWW("POST error:", e.text);
			(e.target as URLLoader).removeEventListener(Event.COMPLETE, check);
			(e.target as URLLoader).removeEventListener(IOErrorEvent.IO_ERROR, onError);
			onComplete.dispatch(false, LoginResult.NETWORK_ERROR, null);
		}
	}
}