package com.poptropica.shells.browser.steps
{
	import com.poptropica.shellSteps.shared.SetActiveProfile;
	
	import flash.net.SharedObject;
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	
	import game.data.comm.PopResponse;
	import game.data.profile.MembershipStatus;
	import game.data.profile.ProfileData;
	import game.managers.ProfileManager;
	import game.proxy.DataStoreRequest;
	import game.scenes.start.login.groups.FillOutLoginProfile;
	import game.systems.entity.EyeSystem;
	import game.util.DataUtils;
	import game.util.ProxyUtils;
	import game.util.SkinUtils;
	
	public class BrowserStepSetActiveProfile extends SetActiveProfile
	{
		/**
		 * Restore the profile from AS2 LSO, determining valid access and login
		 */
		public function BrowserStepSetActiveProfile()
		{
			super();
			stepDescription = "Setting up active profile";
		}
		
		override protected function build():void
		{
			var profileManager:ProfileManager = ProfileManager(this.shellApi.getManager(ProfileManager));
			var login:String = null;
			var pass:String = null;
			if(shell.params)
			{
				for(var p:String in shell.params)
				{
					trace(p + ": " +shell.params[p]);
				}
				login = shell.params.hasOwnProperty("login")? unescape(shell.params.login):null;//retrieve from data sent by dan //unescape(loaderinfo.uname)
				pass = shell.params.hasOwnProperty("pass_hash")? unescape(shell.params.pass_hash):null;// should be passed as a hash //unescape(loaderinfo.pass)
			}
			
			trace("credentials: " + login + " : " + pass);
			
			if(DataUtils.validString(login) && DataUtils.validString(pass))
			{
				shellApi.sceneManager.gameData.overrideScene = "game.scenes.hub.town.Town";
				var filloutProfileGroup:FillOutLoginProfile = new FillOutLoginProfile();
				shellApi.groupManager.add(filloutProfileGroup);
				filloutProfileGroup.login(login, pass, onLogin, false);// should be false when i have a hash to work with
			}
			else
			{
				shellApi.profileManager.add(new ProfileData(), true);
				shellApi.sceneManager.gameData.defaultScene = "game.scenes.start.login.Login";
				built();
			}
		}
		
		private function onLogin(success:Boolean, message:String, keyInfo:Object):void
		{
			//success = false;
			if(success)
			{
				shellApi.profileManager.activeLogin = keyInfo.login;
				fillOutAs2Profile();
			}
			else
			{
				shellApi.sceneManager.gameData.defaultScene = "game.scenes.start.login.Login";
				built();
			}
		}
		
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
			
			built();
		}
	}
}
