package game.scenes.hub.profile.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	
	import game.creators.ui.ToolTipCreator;
	import game.data.display.BitmapWrapper;
	import game.data.ui.TransitionData;
	import game.proxy.Connection;
	import game.scenes.hub.profile.components.Chat;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	import game.util.TextUtils;
	
	public class ChatPopup extends Popup
	{	
		//tracking constants
		private const TRACK_CHOOSE_CATEGORY:String = "ChooseCategory";
		private const TRACK_CHOOSE_MESSAGE:String = "ChooseMessage";
		private const TRACK_SCROLLBAR:String = "Scroll";
		//tracking - is on player's profile or visiting another profile
		private var selfOrFriend:String;
		
		private var loginData:Object;
		
		private var content:MovieClip;
		private var chatWrapper:BitmapWrapper;
		private var colorWrapper:BitmapWrapper;
		private var whiteArrowWrapper:BitmapWrapper;
		private var colorArrowWrapper:BitmapWrapper;
		private var onTxt:TextFormat;
		private var offTxt:TextFormat;
		private var chatsJSON:Object;
		private var chats:MovieClip;
		private var paneButtons:Vector.<Entity> = new <Entity>[];
		private var chatButtons:Vector.<Entity> = new <Entity>[];
		
		public var reloadChats:Function;
		
		public function ChatPopup(ld:Object, container:DisplayObjectContainer=null)
		{
			loginData = ld;
			super(container);
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();
			super.darkenBackground = true;
			super.groupPrefix = "scenes/hub/profile/popups/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["chatPopup.swf"]);
		}
		
		// all assets ready
		override public function loaded():void
		{		
			super.screen = super.getAsset("chatPopup.swf", true) as MovieClip;
			content = screen.content;
			//shellApi.loadFile(shellApi.dataPrefix + 'scenes/hub/profile/chats.xml', xmlLoaded);
			content.mouseChildren = true;
			content.mouseEnabled = false;
			getChatsList();
			
			// for tracking
			selfOrFriend = loginData.playerLogin == loginData.activeLogin ? "self" : "friend";
			
			// this loads the standard close button
			super.loadCloseButton();
			super.loaded();
		}
		
		private function getChatsList():void
		{
			var vars:URLVariables = new URLVariables();
			vars.login = loginData.playerLogin;
			vars.pass_hash = loginData.playerHash;
			vars.dbid = loginData.playerDBID;
			vars.scene = "Profile";
			
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/interface/Chat/listByKeyword", vars, URLRequestMethod.POST, loadChats, myErrorFunction);
		}
		
		private function loadChats(event:Event):void 
		{
			chatsJSON = JSON.parse(event.target.data);
			chats = content.chatsOverlay;
			chatWrapper = super.convertToBitmapSprite(chats.bgWhite,chats.bgWhite.parent, true);
			colorWrapper = super.convertToBitmapSprite(chats.bgColor,chats.bgColor.parent, true);
			colorArrowWrapper = super.convertToBitmapSprite(chats.colorArrow,chats.colorArrow.parent, true);
			whiteArrowWrapper = super.convertToBitmapSprite(chats.whiteArrow,chats.whiteArrow.parent, true);
			
			var offset:int = 0;
			for each(var keyword:Object in chatsJSON.keywords){
				if(keyword.keyword == "Mood"){
					break;
				}
				var wrapper:BitmapWrapper = chatWrapper.duplicate();
				var color:BitmapWrapper = colorWrapper.duplicate();
				var whiteArrow:BitmapWrapper = whiteArrowWrapper.duplicate();
				var colorArrow:BitmapWrapper = colorArrowWrapper.duplicate();
				
				wrapper.sprite.scaleX = wrapper.sprite.scaleY = 1;
				color.sprite.scaleX = color.sprite.scaleY = 1;
				wrapper.sprite.addChild(color.sprite);
				wrapper.sprite.addChild(whiteArrow.sprite);
				wrapper.sprite.addChild(colorArrow.sprite);
				
				color.sprite.x = color.sprite.y = 0;
				whiteArrow.sprite.x = 195;
				whiteArrow.sprite.y = 13.5;
				colorArrow.sprite.x = 195;
				colorArrow.sprite.y = 13.5;
				color.sprite.visible = false;
				whiteArrow.sprite.visible = false;
				
				var msgTxt:TextField = TextUtils.cloneTextField(chats.txt);
				msgTxt.text = keyword.keyword;
				msgTxt.x = 10;
				msgTxt.y = 2;
				wrapper.sprite.addChild(msgTxt);
				
				var entity:Entity = EntityUtils.createMovingEntity( this, wrapper.sprite, chats.chatsContainer);
				entity.get(Spatial).x = 0;
				entity.get(Spatial).y = offset * 30;
				entity.add(new Chat(msgTxt, color.sprite, Number(keyword.keyword_id), 0, entity.get(Spatial).y, whiteArrow.sprite, colorArrow.sprite, false));
				paneButtons.push(entity);
				var interaction:Interaction = InteractionCreator.addToEntity( entity, ["click", "over", "out"], null ); 
				interaction.click.add(clickChatItem);
				interaction.over.add(overChatItem);
				interaction.out.add(outChatItem);
				ToolTipCreator.addUIRollover(entity);
				
				var offset2:int = 0;
				for each(var chat:Object in keyword.chats){						
					var wrapper2:BitmapWrapper = chatWrapper.duplicate();
					var color2:BitmapWrapper = colorWrapper.duplicate();
					
					wrapper2.sprite.scaleX = wrapper2.sprite.scaleY = 1;
					wrapper2.sprite.addChild(color2.sprite);
					
					color2.sprite.x = color2.sprite.y = 0;
					color2.sprite.visible = false;
					
					var msgTxt2:TextField = TextUtils.cloneTextField(chats.txt);
					msgTxt2.text = chat.text;
					msgTxt2.x = 10;
					msgTxt2.y = 2;
					wrapper2.sprite.addChild(msgTxt2);
					
					var entity2:Entity = EntityUtils.createMovingEntity( this, wrapper2.sprite, chats.chatsContainer);
					entity2.get(Spatial).x = 220;
					entity2.get(Spatial).y = offset2 * 30;
					
					entity2.add(new Chat(msgTxt2, color2.sprite, Number(keyword.keyword_id), Number(chat.chat_id), entity2.get(Spatial).y));
					chatButtons.push(entity2);
					var interaction2:Interaction = InteractionCreator.addToEntity( entity2, ["click", "over", "out"], null ); 
					interaction2.click.add(clickChatItem);
					interaction2.over.add(overChatItem);
					interaction2.out.add(outChatItem);
					ToolTipCreator.addUIRollover(entity2);
					
					offset2++;
				}
				offset2 = 0;
				offset++;
			}
			
			onTxt = new TextFormat("Billy Serif", null, "0xFFFFFF");
			offTxt = new TextFormat("Billy Serif", null, "0x636466");
			
			chatWrapper.sprite.visible = false;
			colorWrapper.sprite.visible = false;
			whiteArrowWrapper.sprite.visible = false;
			colorArrowWrapper.sprite.visible = false;
			chats.txt.visible = false;
			
			content.chatsOverlay.mouseEnabled = false;
			content.chatsOverlay.mouseChildren = true;
			
			setOptions(6);
		}
		
		private function setOptions(num:Number):void
		{
			var chat:Chat;
			var counter:Number = 0;
			for(var i:uint=0; i<chatButtons.length; i++)
			{
				chat = chatButtons[i].get(Chat);
				if(chat.pane != num){
					chatButtons[i].get(Spatial).y = chat.startY - 500;
				} else {
					chatButtons[i].get(Spatial).y = chat.startY;
					counter++;
				}
			}
			var pane:Chat;
			for(var j:uint=0; j<paneButtons.length; j++)
			{
				pane = paneButtons[j].get(Chat);
				if(pane.pane != num){
					pane.on = false;
					pane.txt.setTextFormat(offTxt);
					pane.color.visible = false;
					pane.whiteArrow.visible = false;
					pane.colorArrow.visible = true;
				} else {
					pane.on = true;
					pane.txt.setTextFormat(onTxt);
					pane.color.visible = true;
					pane.whiteArrow.visible = true;
					pane.colorArrow.visible = false;
				}
			}
			var largestCol:Number = chatsJSON.keywords.length > counter ? chatsJSON.keywords.length : counter;
			var chatsHeight:Number = largestCol * 30;
			chats.chatsContainer.y = -(chatsHeight / 2);
			chats.bg.height = chatsHeight + 30;
		}
		
		private function clickChatItem(item:Entity):void
		{
			var chat:Chat = item.get(Chat);
			
			// tracking
			var re:RegExp = new RegExp("[^a-zA-Z0-9]","g");
			var name:String = chat.txt.text.replace(re, "");
			
			if(chat.num == 0){
				// tracking
				shellApi.track(TRACK_CHOOSE_CATEGORY, name, selfOrFriend, "Messages");
				
				setOptions(chat.pane);
			} else {
				// tracking
				shellApi.track(TRACK_CHOOSE_MESSAGE, name, selfOrFriend, "Messages");
				
				var vars:URLVariables = new URLVariables();
				vars.login = loginData.playerLogin;
				vars.pass_hash = loginData.playerHash;
				vars.dbid = loginData.playerDBID;
				vars.to_login = loginData.activeLogin;
				vars.scene = "Profile";
				vars.chat_id = chat.num;
				
				var connection:Connection = new Connection();
				connection.connect(shellApi.siteProxy.secureHost + "/interface/Chat/sendMessage", vars, URLRequestMethod.POST, chatSaved, myErrorFunction);
			}
		}
		
		private function chatSaved(event:Event):void 
		{
			reloadChats();
			super.close();
		}
		
		private function overChatItem(item:Entity):void
		{
			var chat:Chat = item.get(Chat);
			if(chat.on == false){
				chat.color.visible = true;
				chat.txt.setTextFormat(onTxt);
				if(chat.whiteArrow != null){
					chat.whiteArrow.visible = true;
					chat.colorArrow.visible = false;
				}
			}
		}
		
		private function outChatItem(item:Entity):void
		{
			var chat:Chat = item.get(Chat);
			if(chat.on == false){
				chat.color.visible = false;
				chat.txt.setTextFormat(offTxt);
				if(chat.whiteArrow != null){
					chat.whiteArrow.visible = false;
					chat.colorArrow.visible = true;
				}
			}
		}
		
		private function myErrorFunction(event:Event):void
		{
			
		}
	};
};