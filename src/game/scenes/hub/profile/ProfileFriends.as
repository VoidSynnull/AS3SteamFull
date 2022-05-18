package game.scenes.hub.profile
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.text.TextField;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.MotionBounds;
	import engine.creators.InteractionCreator;
	
	import game.components.motion.Draggable;
	import game.components.ui.Ratio;
	import game.components.ui.Slider;
	import game.creators.entity.character.CharacterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.character.LookData;
	import game.data.display.BitmapWrapper;
	import game.proxy.Connection;
	import game.ui.elements.ConfirmationDialogBox;
	import game.util.EntityUtils;
	import game.util.TextUtils;

	public class ProfileFriends
	{
		//tracking constants
		private const TRACK_CLICK_FRIEND:String = "ClickFriend";
		private const TRACK_SCROLLBAR:String = "Scroll";
		
		private var profile:Profile;
		private var _interactive:MovieClip;
		private var slider:Entity;
		public var ratio:Ratio;
		private var inventory:MovieClip;
		private var bgWrapper:BitmapWrapper;
		
		private var ringWrapper:BitmapWrapper;
		
		private var noFriends:Boolean = false;
		private var friendsLoaded:uint;
					
		private var friends:Dictionary = new Dictionary();
		public var friendsArray:Array = [];
		
		private var scrollStartY:Number;
		private var scrollMax:Number;
				
		public function ProfileFriends(p:Profile, int:MovieClip)
		{
			profile = p;
			_interactive = int;
			getFriendsList();
		}
		
		private function getFriendsList():void
		{
			var vars:URLVariables = new URLVariables();
			vars.login = profile.loginData.playerLogin;
			vars.pass_hash = profile.loginData.playerHash;
			vars.dbid = profile.loginData.playerDBID;
			vars.lookup_user = profile.loginData.activeLogin;
			vars.limit = 25;
			
			var connection:Connection = new Connection();
			connection.connect(profile.shellApi.siteProxy.secureHost + "/friends/get_friends_list.php", vars, URLRequestMethod.POST, loadFriends, myErrorFunction);
		}
		
		private function loadFriends(event:Event):void 
		{
			var return_vars:URLVariables = new URLVariables(event.target.data);
			
			if(return_vars.answer != "ok")
			{
				profile.noChats();
			} else {
				var obj:Object = JSON.parse(return_vars.json);
				
				friendsLoaded = 0;
				for each(var a:* in obj){
					var array:Array = String(a).split(",");
					var array2:Array = array.slice(3);
					var lookString:String = array2.join(",");
		
					var lookData:LookData = profile.lookConverter.lookDataFromLookString(lookString);
					var f:Object = {login:array[0], name:array[1], look:lookData};
					//remove item (for now, because it can cause a visual artifact)...
					f.look.setValue("item", "empty");
					friends[array[0]] = f;
					friendsArray.push(array[0]);
				}
			}
			var friendsBox:MovieClip = _interactive["friendsBox"];
			inventory = friendsBox["friendsInventory"];
			var itemUIBackground:MovieClip = inventory["itemUIBackground"];
			var ring:MovieClip = inventory["ring"];
			inventory.mask = friendsBox["friendsMask"];
			
			friendsBox.mouseEnabled = false;
			friendsBox.mouseChildren = true;
			
			bgWrapper = profile.convertToBitmapSprite(itemUIBackground, itemUIBackground.parent, false);
			ringWrapper = profile.convertToBitmapSprite(ring, ring.parent, false);
			inventory.removeChild(itemUIBackground);
			
			for (var i:int = 0; i < friendsArray.length; i++)
			{
				createFriendsItem(friendsArray[i], i);
			}
			bgWrapper.sprite.visible = false;
			
			if(friendsArray.length == 0){
				noFriends = true;
				allFriendsItemsLoaded();
				profile.noChats();
			}
		}
		
		private function createFriendsItem(itemId:String, num:Number):void
		{
			++friendsLoaded;
			
			var wrapper:BitmapWrapper = bgWrapper.duplicate();
			wrapper.sprite.x = 120;
			wrapper.sprite.y = num * 60;
			var ring:BitmapWrapper = ringWrapper.duplicate();
			var assetContainer:Sprite = new Sprite();
			assetContainer.scaleX = assetContainer.scaleY = 1;
			
			var txt:TextField = TextUtils.cloneTextField(inventory["friendNameText"]);
			txt.text = friends[itemId].name;
			assetContainer.addChild(txt);
			
			var npcContainer:Sprite = new Sprite();
			npcContainer.scaleX = npcContainer.scaleY = 1;
			
			var type:String = CharacterCreator.TYPE_DUMMY;
			var lookData:LookData = friends[itemId].look;
		
			var npc:Entity = profile.charGroup.createDummy("npcfriend"+num, lookData, "left", "", npcContainer, profile, setupFriendsImage,false,0.5,type,new Point(0,0));
			
			assetContainer.addChild(npcContainer);
			assetContainer.addChild(ring.sprite);
			npcContainer.x = -94;
			npcContainer.y = 90;
			
			var circle:Sprite = new Sprite();
			circle.graphics.beginFill(0xFF794B);
			circle.graphics.drawCircle(0, 0, 25);
			circle.graphics.endFill();
			assetContainer.addChild(circle);
			circle.x = -96;
			circle.y = 22;
			
			npcContainer.mask = circle;			
			wrapper.sprite.addChild(assetContainer);
			
			var entity:Entity = EntityUtils.createMovingEntity( profile, wrapper.sprite, inventory );
			var interaction:Interaction = InteractionCreator.addToEntity( entity, ["click"], wrapper.sprite ); 
			interaction.click.add(clickFriendsItem);
			ToolTipCreator.addUIRollover(entity);
			
			entity.add( new Id(itemId) );
			
			if(friendsLoaded >= friendsArray.length)
				allFriendsItemsLoaded();
		}
		
		private function allFriendsItemsLoaded():void
		{
			inventory["friendNameText"].visible = false;
			inventory["itemUIBackground"].visible = false;
			trace("****************AllFriendsLoaded");
			setupSlider();
		}
		
		private function setupFriendsImage(entity:Entity):void
		{
			profile.stillNPCLoaded(entity, 0.18);
		}
		
		private function clickFriendsItem(item:Entity):void
		{
			var login:String = friends[item.get(Id).id].login;
			var look:String = profile.lookConverter.getLookStringFromLookData(friends[item.get(Id).id].look);
			var name:String = friends[item.get(Id).id].name;
			var separator:String = "|||";
			
			if(login.indexOf("GUEST") != -1)
			{
				
				var dialogBox:ConfirmationDialogBox = profile.shellApi.currentScene.addChildGroup(new ConfirmationDialogBox(1, "User is not registered")) as ConfirmationDialogBox;
				dialogBox.darkenBackground 	= true;
				dialogBox.pauseParent 		= true;
				dialogBox.init(profile.shellApi.currentScene.overlayContainer);
			} else
			{
				// tracking
				profile.shellApi.track(TRACK_CLICK_FRIEND, item.get(Id).id, profile.selfOrFriend, "Friends");
				
				profile.shellApi.sceneManager.clubhouseLogin = login + separator + name + separator + look;
				profile.shellApi.loadScene( Profile );
			}
			
		}
		
		private function setupSlider():void
		{
			var sliderClip:MovieClip = _interactive["friendsBox"]["slider"];
			slider = EntityUtils.createSpatialEntity(profile, sliderClip);
			InteractionCreator.addToEntity(slider, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
			var draggable:Draggable = new Draggable("y");
			slider.add(draggable);
			slider.add(new Slider());
			slider.add(new MotionBounds(new Rectangle(340, 42, 10, 120)));
			slider.add(new Ratio());
			ToolTipCreator.addToEntity(slider);
			draggable.dragging.add(onSliderDrag);
			draggable.drag.add(onSliderStart);
			draggable.drop.add(onSliderDrop);
			
			scrollStartY = inventory.y;
			scrollMax = inventory.height - 175;
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
				profile.shellApi.track(TRACK_SCROLLBAR, "back", profile.selfOrFriend, "Friends");
			} else {
				// tracking
				profile.shellApi.track(TRACK_SCROLLBAR, "forward", profile.selfOrFriend, "Friends");
			}
			
		}
		
		private function onSliderDrag(entity:Entity):void
		{
			var ratio:Ratio = entity.get(Ratio);
			inventory.y = scrollStartY - (scrollMax * ratio.decimal);
		}
		
		private function myErrorFunction(event:Event):void
		{
			trace(event.target.data);
		}
	}
}