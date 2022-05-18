package game.scenes.hub.profile
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.text.TextField;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.character.part.eye.Eyes;
	import game.components.motion.Draggable;
	import game.components.timeline.Timeline;
	import game.components.ui.Ratio;
	import game.components.ui.Slider;
	import game.creators.entity.character.CharacterCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.character.LookData;
	import game.data.display.BitmapWrapper;
	import game.proxy.Connection;
	import game.systems.entity.EyeSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SkinUtils;
	import game.util.TextUtils;

	public class ProfileChats
	{
		//tracking constants
		private const TRACK_SCROLLBAR:String = "Scroll";
		private const TRACK_CLICK_MOOD:String = "ClickMood";
		
		private var profile:Profile;
		private var _interactive:MovieClip;
		
		private var chatBox:MovieClip;
		private var slider:Entity;
		private var inventory:MovieClip;
		private var itemUIBackground:MovieClip;
		private var ring:MovieClip;
		private var bgWrapper:BitmapWrapper;
		private var ringWrapper:BitmapWrapper;
		private var chatBtn1Wrapper:BitmapWrapper;
		private var chatBtn2Wrapper:BitmapWrapper;
		private var chatBtn3Wrapper:BitmapWrapper;
		private var chatBtn4Wrapper:BitmapWrapper;
		private var chatBtn5Wrapper:BitmapWrapper;
		private var chatBtn6Wrapper:BitmapWrapper;
		private var chatsLoaded:uint;
		
		private var chats:Dictionary = new Dictionary();
		public var chatsArray:Array = [];
		
		private var missingAvatarIcons:Array = [];
		private var missingAvatarIconsNames:Array = [];
		
		private var scrollStartY:Number;
		private var scrollMax:Number;
		
		private var chatsJSON:Object;
		private var noChats:Boolean = false;
		
		private var loaded:Boolean = false;
		private var highSeq:Number = 0;
		
		private var extras:Number = 0;
		
		public function ProfileChats(p:Profile, int:MovieClip)
		{
			profile = p;
			_interactive = int;
			getChatsList();
		}
		
		private function getChatsList():void
		{
			var vars:URLVariables = new URLVariables();
			vars.login = profile.loginData.playerLogin;
			vars.pass_hash = profile.loginData.playerHash;
			vars.dbid = profile.loginData.playerDBID;
			vars.scene = "Profile";
			vars.limit = 20;
			vars.last_seq = 0;
			vars.lookup_user = profile.loginData.activeLogin;
			var connection:Connection = new Connection();
			if(!loaded){
				connection.connect(profile.shellApi.siteProxy.secureHost + "/interface/Chat/readMessages", vars, URLRequestMethod.POST, loadChats, myErrorFunction);
			} else {
				connection.connect(profile.shellApi.siteProxy.secureHost + "/interface/Chat/readMessages", vars, URLRequestMethod.POST, checkChats, myErrorFunction);
			}
			
		}
		
		private function loadChats(event:Event):void 
		{
			var counter:Number = 0;
			chatsJSON = JSON.parse(event.target.data);
			trace("loadChats: " + chatsJSON.answer);
			// sometimes I get an answer of no-such-friend-login
			if(chatsJSON.answer == "ok")
			{
				for each(var message:Object in chatsJSON.messages){
					chats["message"+message.seq] = message;
					chatsArray.push("message"+message.seq);
					if(message.seq > highSeq){
						highSeq = message.seq;
					}
					
					if(profile.friendNames.indexOf(message.login) == -1){
						counter++;
						profile.friendNames.push(message.login);
						
						var npcContainer:Sprite = new Sprite();
						npcContainer.scaleX = npcContainer.scaleY = 1;
						var type:String = CharacterCreator.TYPE_DUMMY;
						var lookData:LookData = profile.lookConverter.lookDataFromLookString(message.look);
						var npc:Entity = profile.charGroup.createDummy("npcchat"+counter, lookData, "left", "", npcContainer, profile, stillNPCLoaded,false,0.5,type,new Point(0,0));
					}
				}
			}
			if(counter == 0)
			{
				setupChatsBox();
			}
		}
		
		private function checkChats(event:Event):void 
		{
			var counter:Number = 0;
			chatsJSON = JSON.parse(event.target.data);
			trace("checkChats: " + chatsJSON.answer);
			if(chatsJSON.answer == "ok")
			{
				for each(var message:Object in chatsJSON.messages){
					if(profile.friendNames.indexOf(message.login) == -1) {
						counter++;
						profile.friendNames.push(message.login);
						
						var npcContainer:Sprite = new Sprite();
						npcContainer.scaleX = npcContainer.scaleY = 1;
						var type:String = CharacterCreator.TYPE_DUMMY;
						var lookData:LookData = profile.lookConverter.lookDataFromLookString(message.look);
						var npc:Entity = profile.charGroup.createDummy("npcchat"+counter, lookData, "left", "", npcContainer, profile, stillNPCLoaded,false,0.5,type,new Point(0,0));
					}
				}
			}
			if(counter == 0)
			{
				addChats();
			}
		}
		
		private function addChats(event:Event=null):void 
		{
			if(chatsJSON.answer == "ok")
			{
				for each(var message:Object in chatsJSON.messages){
					if(message.seq > highSeq){
						chats["message"+message.seq] = message;
						chatsArray.unshift("message"+message.seq);
						createChatsItem("message"+message.seq, 0);
						highSeq = message.seq;
					} else {
						var e:Entity = profile.getEntityById("message"+message.seq);
						if(e != null){
							e.get(Spatial).y += 60;
							var sprite:Sprite = Sprite(e.get(Display).displayObject);
							var container:Sprite = Sprite(sprite.getChildByName("container"));
							var timeTxt:TextField = TextField(container.getChildByName("timeTxt"));
							var timePassed:Number = message.viewed_time - message.sent_time;
							timeTxt.text = convertTime(timePassed);
						} 
					}
				}
			}
			scrollMax = inventory.height - 175;
		}
		
		public function stillNPCLoaded(entity:Entity):void
		{
			entity.get(Spatial).scaleX = entity.get(Spatial).scaleY = 0.2;
			entity.get(Timeline).paused = true;
			var eyeEntity:Entity = CharUtils.getPart( entity, CharUtils.EYES_PART );
			if( eyeEntity != null )
			{
				var eyes:Eyes = eyeEntity.get(Eyes);
				if( eyes != null )
				{
					SkinUtils.setEyeStates(entity, eyes.permanentState, EyeSystem.FRONT, true);
					eyes.canBlink = false;
				}
			}
			Command.callAfterDelay(bitmapNPC, 100, entity);
		}
		
		private function bitmapNPC(entity:Entity):void 
		{
			var glowF : GlowFilter = new GlowFilter(0xFFFFFF, .9, 6, 6, 8, 1);
			var cwrapper:BitmapWrapper = profile.convertToBitmapSprite(entity.get(Display).displayObject, null, false, 0.15);
			cwrapper.sprite.scaleX = cwrapper.sprite.scaleY = 0.15;
			profile.friendBitmaps.push(cwrapper);
			cwrapper.sprite.visible = false;
			if(profile.friendBitmaps.length == profile.friendNames.length) { 
				if(!loaded){
					setupChatsBox();
				} else {
					addChats();
				}	
			}
			profile.removeEntity(entity);
		}
		
		private function setupChatsBox():void 
		{
			_interactive["chatsBox"].mouseEnabled = false;
			_interactive["chatsBox"].mouseChildren = true;
			inventory = _interactive["chatsBox"]["chatsInventory"];
			itemUIBackground = inventory["itemUIBackground"];
			ring = inventory["ring"];
			var chatsBox:MovieClip = _interactive["chatsBox"];
			var chatBtn1:MovieClip = chatsBox["chatBtn1"];
			var chatBtn2:MovieClip = chatsBox["chatBtn2"];
			var chatBtn3:MovieClip = chatsBox["chatBtn3"];
			var chatBtn4:MovieClip = chatsBox["chatBtn4"];
			var chatBtn5:MovieClip = chatsBox["chatBtn5"];
			var chatBtn6:MovieClip = chatsBox["chatBtn6"];
			
			bgWrapper = profile.convertToBitmapSprite(itemUIBackground, itemUIBackground.parent, false);
			ringWrapper = profile.convertToBitmapSprite(ring, ring.parent, false);
			chatBtn1Wrapper = profile.convertToBitmapSprite(chatBtn1, chatBtn1.parent, false);
			chatBtn2Wrapper = profile.convertToBitmapSprite(chatBtn2, chatBtn2.parent, false);
			chatBtn3Wrapper = profile.convertToBitmapSprite(chatBtn3, chatBtn3.parent, false);
			chatBtn4Wrapper = profile.convertToBitmapSprite(chatBtn4, chatBtn4.parent, false);
			chatBtn5Wrapper = profile.convertToBitmapSprite(chatBtn5, chatBtn5.parent, false);
			chatBtn6Wrapper = profile.convertToBitmapSprite(chatBtn6, chatBtn6.parent, false);
			
			chatsLoaded = 0;
			
			inventory["itemUIBackground"].visible = false;
			inventory.mask = _interactive["chatsBox"]["chatMask"];			
			
			for (var i:int = 0; i < chatsArray.length; i++)
			{
				createChatsItem(chatsArray[i], i);
			}
			
			bgWrapper.sprite.visible = false;
			setupBtn(chatBtn1);
			setupBtn(chatBtn2);
			setupBtn(chatBtn3);
			setupBtn(chatBtn4);
			setupBtn(chatBtn5);
			setupBtn(chatBtn6);
			
			var chatBtn:Entity = ButtonCreator.createButtonEntity(MovieClip(_interactive["chatsBox"]["chatBtn"]), profile);
			chatBtn.remove(Timeline);
			var interaction:Interaction = chatBtn.get(Interaction);
			interaction.click.add( clickChatBtn );
			
			if(chatsArray.length == 0){
				noChats = true;
				allChatsItemsLoaded();
			}
		}
		
		private function clickChatBtn(entity:Entity):void 
		{
			profile.clickChatBtn(entity);
		}
		
		private function setupBtn(clip:MovieClip):void 
		{
			var btn:Entity = ButtonCreator.createButtonEntity(clip, profile);
			btn.remove(Timeline);
			btn.get(Id).id = clip.name;
			var interacton:Interaction = btn.get(Interaction);
			interacton.click.add( clickBtn );
		}
		
		private function clickBtn(entity:Entity):void 
		{
			var id:Number;
			
			// tracking
			profile.shellApi.track(TRACK_CLICK_MOOD, id, profile.selfOrFriend, "Messages");
			
			switch(entity.get(Id).id){
				case "chatBtn1":
					id = 229;
					break;
				case "chatBtn2":
					id = 230;
					break;
				case "chatBtn3":
					id = 231;
					break;
				case "chatBtn4":
					id = 232;
					break;
				case "chatBtn5":
					id = 233;
					break;
				case "chatBtn6":
					id = 234;
					break;
			}
			var vars:URLVariables = new URLVariables();
			vars.login = profile.loginData.playerLogin;
			vars.pass_hash = profile.loginData.playerHash;
			vars.dbid = profile.loginData.playerDBID;
			vars.to_login = profile.loginData.activeLogin;
			vars.scene = "Profile";
			vars.chat_id = id;
			
			var connection:Connection = new Connection();
			connection.connect(profile.shellApi.siteProxy.secureHost + "/interface/Chat/sendMessage", vars, URLRequestMethod.POST, reloadChats, myErrorFunction);
		}
		
		private function createChatsItem(itemId:String, n:Number):void 
		{
			++chatsLoaded;
			
			var num:Number = profile.friendNames.indexOf(chats[itemId].login);
			//if(num != -1)
			//{
				var wrapper:BitmapWrapper = bgWrapper.duplicate();
				wrapper.sprite.x = 134;
				wrapper.sprite.y = n * 60 + 30;
				var ring:BitmapWrapper = ringWrapper.duplicate();
				
				var assetContainer:Sprite = new Sprite();
				assetContainer.name = "container";
				assetContainer.scaleX = assetContainer.scaleY = 1;
				
				if(num != -1){
					var circle:Sprite = new Sprite();
					circle.graphics.beginFill(0xFF794B);
					circle.graphics.drawCircle(0, 0, 20);
					circle.graphics.endFill();
					assetContainer.addChild(circle);
					circle.x = -110;
					circle.y = 0;
					
					var char:BitmapWrapper = profile.friendBitmaps[num].duplicate(); 
					var charSprite:Sprite = char.sprite;
					assetContainer.addChild(charSprite);
					charSprite.scaleX = charSprite.scaleY = 0.15;
					charSprite.x = -108;
					charSprite.y = 16;
					var glowF : GlowFilter = new GlowFilter(0xFFFFFF, .9, 4, 4, 4, 1);
					charSprite.filters = [glowF];
					charSprite.mask = circle;
				} 
				
				assetContainer.addChild(ring.sprite);
				
				var timeTxt:TextField = TextUtils.cloneTextField(inventory["timeTxt"]);
				var nameTxt:TextField = TextUtils.cloneTextField(inventory["nameTxt"]);
				timeTxt.visible = true;
				nameTxt.visible = true;
				var timePassed:Number = chats[itemId].viewed_time - chats[itemId].sent_time;
				var txt:String = convertTime(timePassed);
				timeTxt.text = txt == "just now" ? txt : txt + " ago";
				nameTxt.text = chats[itemId].avatar_name;
				
				assetContainer.addChild(timeTxt);
				assetContainer.addChild(nameTxt);
				
				if(chats[itemId].message_id >= 229 && chats[itemId].message_id <= 234) {
					var wrapperNum:Number = Number(chats[itemId].message_id)-228;
					var emote:BitmapWrapper = this["chatBtn"+wrapperNum+"Wrapper"].duplicate();
					emote.sprite.x = -64;
					emote.sprite.y = 7;
					emote.bitmap.smoothing = true;
					emote.sprite.scaleX = emote.sprite.scaleY = 0.75;
					assetContainer.addChild(emote.sprite);
				} else {
					var msgTxt:TextField = TextUtils.cloneTextField(inventory["messageTxt"]);
					msgTxt.visible = true;
					msgTxt.text = chats[itemId].message;
					assetContainer.addChild(msgTxt);
				}
				
				wrapper.sprite.addChild(assetContainer);
				
				var entity:Entity = EntityUtils.createMovingEntity( profile, wrapper.sprite, inventory );
				//var interaction:Interaction = InteractionCreator.addToEntity( entity, ["click"], wrapper.sprite ); 
				//interaction.click.add(clickChatsItem);
				//ToolTipCreator.addUIRollover(entity);
				entity.add( new Id(itemId) );	
			//}
				
			if(chatsLoaded >= chatsArray.length && loaded == false)
				allChatsItemsLoaded();
		}
		
		private function allChatsItemsLoaded():void 
		{
			trace("****************AllChatsLoaded");
			inventory["messageTxt"].visible = false;
			inventory["timeTxt"].visible = false;
			inventory["nameTxt"].visible = false;
			setupSlider();
			loaded = true;
			
			extras = 0;
			//createExtraIcons();
		}
		
		private function clickChatsItem(entity:Entity):void 
		{
			//trace(entity.get(Id).id);
			
		}
		
		public function reloadChats(event:Event=null):void 
		{
			if(event != null){
				chatsJSON = JSON.parse(event.target.data);
				if(chatsJSON.answer == "ok")
				{
					getChatsList();
				}
			} else {
				getChatsList();
			}
		}
		
		private function setupSlider():void
		{
			var sliderClip:MovieClip = _interactive["chatsBox"]["slider"];
			slider = EntityUtils.createSpatialEntity(profile, sliderClip);
			InteractionCreator.addToEntity(slider, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
			var draggable:Draggable = new Draggable("y");
			slider.add(draggable);
			slider.add(new Slider());
			slider.add(new MotionBounds(new Rectangle(450, 27, 10, 120)));
			slider.add(new Ratio());
			ToolTipCreator.addToEntity(slider);
			draggable.dragging.add(onSliderDrag);
			draggable.drag.add(onSliderStart);
			draggable.drop.add(onSliderDrop);
			
			scrollStartY = inventory.y;
			scrollMax = inventory.height - 175;
			profile.setReady();
		}
		
		private function onSliderDrag(entity:Entity):void
		{
			var ratio:Ratio = entity.get(Ratio);
			inventory.y = scrollStartY - (scrollMax * ratio.decimal);
		}
		private var sliderStart:Number;
		private function onSliderStart(entity:Entity):void
		{
			sliderStart = entity.get(Ratio).decimal;
		}
		private function onSliderDrop(entity:Entity):void
		{
			if(sliderStart - entity.get(Ratio).decimal > 0){
				// tracking
				profile.shellApi.track(TRACK_SCROLLBAR, "back", profile.selfOrFriend, "Messages");
			} else {
				// tracking
				profile.shellApi.track(TRACK_SCROLLBAR, "forward", profile.selfOrFriend, "Messages");
			}
			
		}
		
		private function myErrorFunction(event:Event):void
		{
			
		}
		
		private function convertTime(seconds:Number):String
		{
			var sec:Number = seconds;
			var min:Number = Math.floor(seconds / 60 );
			var hr:Number = Math.floor(seconds / (60 * 60));
			var day:Number = Math.floor(seconds / (60 * 60 * 24));
			var year:Number = Math.floor(seconds / ( 60 * 60 * 24 * 365));
			
			var msg:String;
			if(year > 0){
				msg = year > 1 ? year+" years" : year+" year";
			} else if (day > 0){
				msg = day > 1 ? day+" days" : day+" day";
			} else if (hr > 0){
				msg = hr > 1 ? hr+" hours" : hr+" hour";
			} else if (min > 0){
				msg = min > 1 ? min+" minutes" : min+" minute";
			} else if(sec > 0){
				msg = sec > 1 ? sec+" seconds" : sec+" second";
			} else {
				msg = "just now";
			}
			
			return msg;
		}
	}
}