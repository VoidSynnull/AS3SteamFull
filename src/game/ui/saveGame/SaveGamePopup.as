package game.ui.saveGame
{
	import com.adobe.crypto.MD5;
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	
	import ash.core.Entity;
	
	import engine.util.Command;
	
	import game.creators.ui.ButtonCreator;
	import game.data.PlayerLocation;
	import game.data.character.LookConverter;
	import game.data.comm.PopResponse;
	import game.data.profile.ProfileData;
	import game.data.ui.TransitionData;
	import game.proxy.Connection;
	import game.proxy.DataStoreRequest;
	import game.scenes.start.login.popups.WarningPopup;
	import game.ui.hud.Hud;
	import game.ui.popup.Popup;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.InputFieldUtil;
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TextUtils;
	import game.utils.AdUtils;
	
	public class SaveGamePopup extends Popup
	{
		public var savedGame:Boolean = false;
		
		private var content:MovieClip;
		private var Iname:TextField;
		private var Ipass:TextField;
		private var Iretype:TextField;
		private var userName:TextField;
		
		private var start:Entity;
		private var complete:Entity;
		
		private var suggestBtn:Entity;
		
		private var targetTF:TextField;
		
		private var fields:Array = ["Iname","Ipass","Iretype"];
		
		private var chars:String = "";
		private var nums:String = "";
		private var processingRequest:Boolean;
		private var grantedAccess:Boolean;
		
		public function SaveGamePopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();
			super.darkenBackground = true;
			super.groupPrefix = "ui/saveGame/";
			super.screenAsset = "saveGamePopup.swf";
			super.init(container);
			super.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			content = screen.content;
			content.x = shellApi.viewportWidth/2;
			content.y = shellApi.viewportHeight/2;
			
			var bg:MovieClip = content["bg"];
			bg.width = shellApi.viewportWidth;
			bg.height = shellApi.viewportHeight;
			
			var parentContainer:MovieClip = content["start"];
			
			var warningContainer:MovieClip = parentContainer["overlayContainer"];
			warningContainer.x = -shellApi.viewportWidth/2;
			warningContainer.y = -shellApi.viewportHeight/2;
			
			start = EntityUtils.createSpatialEntity(this, parentContainer);
			
			for(var i:int = 0; i < fields.length; i++)
			{
				var fieldName:String = fields[i];
				var tf:TextField;
				if(PlatformUtils.isIOS && i > 0)//(not username)
				{
					tf = TextUtils.refreshText(parentContainer[fieldName], "Arial");
				}
				else
				{
					tf = TextUtils.refreshText(parentContainer[fieldName], "Billy Serif");
				}
				tf.tabIndex = i+1;
				tf.restrict = i == 0?"\u0021-\u007E^%&;@":"\u0021-\u007E^%&;";
				tf.addEventListener(KeyboardEvent.KEY_DOWN, checkPressedEnter);
				tf.maxChars = 50;
				this[fieldName] = tf;
				InputFieldUtil.setUpFieldToScroll(tf, shellApi);
				tf.addEventListener(FocusEvent.FOCUS_IN, Command.create(showHintOnFocusChange, true) );
				tf.addEventListener(FocusEvent.FOCUS_OUT, Command.create(showHintOnFocusChange, false) );
				TextUtils.refreshText(parentContainer[fieldName+"Hint"]);
			}
			
			targetTF = Iname;
			
			var btn:Entity = ButtonCreator.createButtonEntity(parentContainer["regBtn"],this, onReg);
			
			parentContainer = content["complete"];
			complete = EntityUtils.createSpatialEntity(this, parentContainer);
			
			userName = TextUtils.refreshText(parentContainer["Name"]);
			btn = ButtonCreator.createButtonEntity(parentContainer["okBtn"], this, onOk);
			
			EntityUtils.visible(complete, false);
			
			loadCloseButton();
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
			// for whatever reason the carret always starts at the beginning
			if(PlatformUtils.isMobileOS && inFocus)
			{
				targetTF.setSelection(targetTF.text.length, targetTF.text.length);
			}
		}
		
		private function checkPressedEnter(event:KeyboardEvent):void
		{
			if(this.paused || !this.isReady)
				return;
			
			targetTF = event.currentTarget as TextField;
			
			if(event.keyCode == Keyboard.ENTER)
			{
				if(!DataUtils.validString(targetTF.text))
					return;
				
				var index:int = fields.indexOf(targetTF.name);
				index++;
				if(index >= fields.length)
					onReg(null);
				else
					content.stage.focus = targetTF.parent[fields[index]];
			}
		}
		
		private function onOk(entity:Entity):void
		{
			super.close();
		}
		
		private function onReg(entity:Entity):void
		{
			var errorMessage:String = "";
			// basic data vlidation
			if(!DataUtils.validString(Iname.text))
			{
				errorMessage = "Enter a username, please";
				shellApi.track("RegisterError", "EnterUserName");
				openErrorPopup(errorMessage);
				return;
			}
			
			if(!DataUtils.validString(Ipass.text))
			{
				errorMessage = "Enter a password, please";
				shellApi.track("RegisterError", "EnterPassword");
				openErrorPopup(errorMessage);
				return;
			}
			else
			{
				if(Ipass.text.length < 5)
				{
					errorMessage = "The password is too short";
					shellApi.track("RegisterError", "PasswordToShort");
					openErrorPopup(errorMessage);
					return;
				}
			}
			
			if(!DataUtils.validString(Iretype.text))
			{
				errorMessage = "Confirm your password, please";
				shellApi.track("RegisterError", "NeedToConfirmPassword");
				openErrorPopup(errorMessage);
				return;
			}
			else
			{
				if(Ipass.text != Iretype.text)
				{
					errorMessage = "The password and the retyped password don't match.";
					shellApi.track("RegisterError", "PasswordsDoNotMatch");
					openErrorPopup(errorMessage);
					return;
				}
			}
			
			var fullLogin:String = Iname.text;
			
			if(Ipass.text == "password" || Ipass.text == fullLogin)
			{
				errorMessage = "The password is too easy to guess";
				shellApi.track("RegisterError", "PasswordTooEasy");
				openErrorPopup(errorMessage);
				return;
			}
			
			
			// determing if there is any sort of suffix numeration going on
			// if ther is, breaking it up into basic name and numeric suffix
			if(fullLogin.length > 1)
			{
				var charCode:int;
				// loop through login backwards to determine a numeric suffix if any
				for(var c:int = fullLogin.length-1; c>=0; c--)
				{
					charCode = fullLogin.charCodeAt(c);
					if(charCode > 47 && charCode < 58)
					{
						nums = fullLogin.charAt(c) + nums;
					}
					else
					{
						chars = fullLogin.substr(0,c+1);
						break;
					}
				}
				
				if(chars.length == 0)
				{
					chars = nums.substr(0, 1);
					nums = nums.substr(1);
				}
			}
			else
			{
				chars = fullLogin;
			}
			// final check that everything worked out ok
			if(!DataUtils.validString(chars))
			{
				errorMessage = "Please enter a different username.";
				shellApi.track("RegisterError", "EnterNewUsername");
				openErrorPopup(errorMessage);
				return;
			}
			
			fillOutRequest();
		}
		
		private function fillOutRequest(...args):void
		{
			if(!shellApi.networkAvailable())
			{
				openErrorPopup("Network not available, reconnect and try again.");
				return;
			}
			if(processingRequest)
				return;
			
			processingRequest = true;
			// login password and confirmation met all minium standards
			
			// so now we prep server call with player data
			
			// key data objects
			var profile:ProfileData = shellApi.profileManager.active;
			var as2Data:Object = ProxyUtils.as2lso.data;
			var postVars:URLVariables = new URLVariables();
			
			//key login info
			postVars.login = chars;
			postVars.num = nums;
			postVars.pass_hash = MD5.hash(Ipass.text.toLowerCase());
			// this is only occurs if friended from a common room (which is as2 only)
			if(as2Data.isPartiallyRegistered)
			{
				postVars.partial_login = as2Data.login;
			}
			//look
			var lookConverter:LookConverter = new LookConverter();
			postVars.look = lookConverter.getLookStringFromLookData(lookConverter.lookDataFromPlayerLook(profile.look), shellApi.player);
			//location
			var location:PlayerLocation = profile.lastScene[shellApi.island];
			if(location)
			{
				postVars.lastroom = shellApi.sceneName;
				postVars.island = ProxyUtils.convertIslandToServerFormat(shellApi.island);
				postVars.lastx = location.locX;
				postVars.lasty = location.locY;
			}
			
			//name age and gender
			postVars.fname = profile.avatarFirstName;
			postVars.lname = profile.avatarLastName;
			postVars.age = profile.age;
			postVars.gender = profile.gender == SkinUtils.GENDER_MALE? "M":"F";
			
			//items
			var array:Array = getDataSet("inventory", "items");
			postVars.inv = array.toString();
			//removed items
			array = getDataSet("removedItems", null);
			postVars.picked = array.toString();
			//events
			array = getDataSet("completedEvents", "events");
			postVars.events_list = array.toString();
			
			// user data
			var userData:Object = as2Data.userData;
			if(userData)
				postVars.user_data = JSON.stringify(userData);
			else
				postVars.user_data = "";
			
			//scores
			var scoresStr:String = "";
			for(var gameName:String in profile.scores)
			{
				var gameData:Object = profile.scores[gameName];
				var score:* = gameData[gameName+"Score"];
				var wins:* = gameData[gameName+"Wins"];
				var losses:* = gameData[gameName+"Losses"];
				if (score != undefined || wins != undefined || losses != undefined)
				{
					wins = wins == undefined?0:wins;
					losses = losses == undefined?0:losses;
					score = score == undefined?0:score;
					if (scoresStr.length > 0) scoresStr += ";";
					scoresStr += gameName+","+score+","+wins+","+losses;
				}
			}
			postVars.scores = scoresStr;
			
			// request
			
			var url:String = super.shellApi.siteProxy.secureHost + "/reguser.php";
			
			var req:URLRequest = new URLRequest(url);
			
			req.method = URLRequestMethod.POST;
			
			req.data = postVars;
			var loader:URLLoader = new URLLoader(req);
			
			SceneUtil.lockInput(this);
			
			loader.addEventListener(Event.COMPLETE,check);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onRegisterError);
			loader.load(req);
		}
		//get data from the as2 data if possible but use profile as a fall back if possible
		private function getDataSet(as2Property:String, profileProperty:String):Array
		{
			var array:Array = [];
			
			var profile:ProfileData = shellApi.profileManager.active;
			var as2Data:Object = ProxyUtils.as2lso.data;
			
			var source:*;
			var as2:Boolean = true;
			var dataSet:Array;
			var valid:Boolean = as2Data.hasOwnProperty(as2Property);
			
			if(valid)
			{
				source = as2Data[as2Property];
			}
			else if(DataUtils.validString(profileProperty) && profile.hasOwnProperty(profileProperty))//local
			{
				source = profile[profileProperty];
				as2 = false;
				valid = true;
			}
			
			if(!valid)
			{
				return array;
			}
			
			for (var island:String in source)
			{
				dataSet = source[island];
				if(as2)
					array = array.concat(dataSet);
				else
				{
					for(var i:int = 0; i < dataSet.length; i++)
					{
						if(profileProperty == "items")
						{
							var itemId:Number = ProxyUtils.convertItemToServerFormat(dataSet[i],island, ProxyUtils.itemToIdMap[island]);
							trace(island + ": " + itemId);
							if(!isNaN(itemId))
								array.push(itemId);
						}
						else
						{
							array.push(ProxyUtils.convertEventToServerFormat(dataSet[i], island));
						}
					}
				}
			}
			
			return array;
		}
		
		protected function onRegisterError(event:IOErrorEvent):void
		{
			trace(event.toString());
			SceneUtil.lockInput(this, false);
		}
		
		protected function check(event:Event):void
		{
			SceneUtil.lockInput(this, false);
			var errorMessage:String = "";
			var response:String = event.target.data;
			var parts:Array = response.split("&");
			var answer:String = parts[0];
			//first part will alwyas be answer=(which is 7 characters long)
			answer = answer.substr(7);
			trace("Answer: " + answer);
			trace(shellApi.siteProxy.secureHost+shellApi.siteProxy.commData.grantMeAccess);
			processingRequest = false;
			if(parts.length == 1)
			{
				if(answer == "logout")
				{
					if(!grantedAccess  && shellApi.siteProxy.secureHost.indexOf("xpop") >= 0)
					{
						
						grantedAccess = true;
						var req:URLRequest = new URLRequest(shellApi.siteProxy.secureHost+shellApi.siteProxy.commData.grantMeAccess);
						req.method = URLRequestMethod.POST;
						var loader:URLLoader = new URLLoader(req);
						loader.load(req);
						loader.addEventListener(Event.COMPLETE,fillOutRequest);
						return;
					}
					else
					{
						errorMessage = "There was an error connecting to the database. Try a bit later";
					}
				}
				else
				{
					errorMessage = "There was a problem.";
				}
			}
			else
			{
				var value:String = parts[1];
				var startIndex:int = value.indexOf("=");
				value = value.substr(startIndex+1);
				trace("Value: " + value);
				if(answer == "ok")
				{
					var dbid:String = parts[2];
					//dbid=(which is 5 chars)
					dbid = dbid.substr(5);
					// fill out data from successful save data
					var profile:ProfileData = shellApi.profileManager.active;
					var lso:SharedObject = ProxyUtils.as2lso;
					var as2Data:Object = lso.data;
					profile.dbid = as2Data.dbid = dbid;
					profile.isGuest = false;
					as2Data.Registred = true;
					var oldLogin:String = profile.login;
					profile.login = as2Data.login = value;
					profile.pass_hash = as2Data.password = MD5.hash(Ipass.text.toLowerCase());
					
					as2Data.friends_profile = 0;
					as2Data.hub = 0;
					lso.flush();
					// we will not be supporting island photos
					userName.text = value;
					
					// remove the old entry and add in the new
					delete shellApi.profileManager.profiles[oldLogin];
					shellApi.profileManager.add(profile, true);
					
					// will attempt again later
					//sendFinishedIslands(as2Data);
					
					registerSuccess();
				}
				else if(answer == "exists")
				{
					errorMessage = "that username already exists! try:\n" + value;
					//suggest.text = value;
				}
			}
			if(DataUtils.validString(errorMessage))
			{
				chars = nums = "";
				shellApi.track("RegisterError", answer);
				openErrorPopup(errorMessage);
			}
		}
		
		private function openErrorPopup(message:String):void
		{
			var overlayContainer:MovieClip = content["start"]["overlayContainer"];
			var warning:WarningPopup = addChildGroup(new WarningPopup(overlayContainer)) as WarningPopup;
			warning.ConfigPopup("oops", message);
			warning.removed.addOnce(resetFocus);
		}
		
		private function resetFocus(group:Popup):void
		{
			groupContainer.stage.focus = targetTF;
		}
		
		private function registerSuccess():void
		{
			if(PlatformUtils.isMobileOS)
			{
				AppConfig.storeToExternal = true;
				AppConfig.retrieveFromExternal = true;
			}
			
			savedGame = true;
			
			EntityUtils.visible(start, false);
			EntityUtils.visible(complete);
			shellApi.saveGame();
			var hud:Hud = getGroupById(Hud.GROUP_ID) as Hud;
			hud.hideButton(Hud.SAVE);
			shellApi.triggerEvent("saved_game");
			shellApi.track("RegistrationCompleted");
			// if external interface and not iframe
			if ((ExternalInterface.available) && (!shellApi.cmg_iframe))
			{
				ExternalInterface.call("completedRegistration", shellApi.profileManager.active.login);
			}
			else if (AppConfig.mobile)
			{
				AdUtils.sendTrackingPixels(shellApi, "cpmstar", "https://server.cpmstar.com/action.aspx?advertiserid=6625&gif=1");
			}
			
			// get shards from local lso
			shellApi.getUserField("shards_found", "tutorial", gotShards, false);
		}
		
		private function gotShards(shards:Array):void
		{
			if (shards != null)
			{
				for each (var shard:String in shards)
				{
					// award shard items (back-end will trigger credits)
					shellApi.siteProxy.store(DataStoreRequest.itemGainedStorageRequest(shard, "tutorial"), getCredits);
				}
			}
			else
			{
				getCredits(null);
			}
		}

		private function getCredits(response:PopResponse):void
		{
			// need to fetch credits now
			var vars:URLVariables = new URLVariables();
			// set params to send to server
			vars.name = shellApi.profileManager.active.login;
			vars.pass_hash = shellApi.profileManager.active.pass_hash;
			vars.dbid = shellApi.profileManager.active.dbid;
			// add other params
			vars.limit = 0;
			vars.offset = 0;
			
			// make php call to server
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/get_credits.php", vars, URLRequestMethod.POST, gotCredits, gotError);
		}
		
		private function sendFinishedIslands(as2Data:Object):void
		{
			if (as2Data.login != "" && as2Data.Registred)
			{
				//var islandCompletions:Object = FunBrain_so.data.islandCompletions;
				var startIslandData:Object = null;
				var finishIslandData:Object = null;
				//var startTime:Number = 0;
				
				if (as2Data.islandTimes != undefined)
				{
					for (var n in as2Data.islandTimes)
					{
						if (as2Data.islandTimes[n].start != undefined)
						{					
							if (startIslandData == null)
							{
								startIslandData = new Object();
							}
							
							startIslandData[n] = as2Data.islandTimes[n].start;
							
							if (as2Data.islandTimes[n].end != undefined)
							{
								if (finishIslandData == null)
								{
									finishIslandData = new Object();
								}
								
								finishIslandData[n] = as2Data.islandTimes[n].end;
							}
						}
					}
					
					if (startIslandData != null)
					{
						var completionSender:URLVariables = new URLVariables();
						
						completionSender.login = as2Data.login;
						completionSender.pass_hash = as2Data.password;
						completionSender.dbid = as2Data.dbid;
						
						convertAssociativeArrayToURLEncoding(startIslandData, "islands", completionSender);
						
						var connection:Connection = new Connection();
						connection.connect(shellApi.siteProxy.secureHost + "/started_islands.php", completionSender, URLRequestMethod.POST, null, gotError);
						
						if (finishIslandData != null)
						{
							completionSender = new URLVariables();
							
							completionSender.login = as2Data.login;
							completionSender.pass_hash = as2Data.password;
							completionSender.dbid = as2Data.dbid;
							
							convertAssociativeArrayToURLEncoding(finishIslandData, "islands", completionSender);
							connection = new Connection();
							connection.connect(shellApi.siteProxy.secureHost + "/finished_islands.php", completionSender, URLRequestMethod.POST, null, gotError);
						}
					}
				}
			}
		}

		private function convertAssociativeArrayToURLEncoding(sourceArray:Object, targetArrayName:String, targetObject:Object):void
		{		
			for (var i in sourceArray) 
			{
				targetObject[targetArrayName + "[" + i + "]"] = sourceArray[i];
			}
		}
		
		private function gotCredits(e:Event):void
		{
			// parse data
			var return_vars:URLVariables = new URLVariables(e.target.data);
			// credits should be 75
			var credits:Number = Number(return_vars.credits);
			// if valid number
			if (!isNaN(credits))
			{
				shellApi.profileManager.active.credits = credits;
			}
		}
		
		private function gotError(e:IOErrorEvent):void
		{
			trace("GetCreditsError: " + e.errorID)
			shellApi.logWWW("GetCreditsError: " + e.errorID);
		}
	}
}