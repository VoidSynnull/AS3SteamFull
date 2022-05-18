package game.ui.multiplayer.chat
{
	import com.poptropica.AppConfig;
	import com.smartfoxserver.v2.entities.User;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Rectangle;
	import flash.net.SharedObject;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.multiplayer.chat.MenuBalloon;
	import game.components.multiplayer.chat.MenuBalloonRow;
	import game.components.multiplayer.chat.MsgBalloon;
	import game.components.ui.ToolTipActive;
	import game.creators.ui.ButtonCreator;
	import game.proxy.Connection;
	import game.scene.template.SceneUIGroup;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;
	
	
	public class MenuBalloonCreator
	{
		public function MenuBalloonCreator(chat:Chat, clip:MovieClip, msgs:Entity=null)
		{
			_chat = chat;
			_clip = clip;
			if(msgs != null)
				_categoryBalloonEntity = msgs;
		}
		
		public function create():Entity
		{
			_categoryBalloonEntity = new Entity();
			
			_categoryBalloonEntity = EntityUtils.createSpatialEntity(_chat, _clip);
			var menuBalloon:MenuBalloon = new MenuBalloon(_chat.shellApi.smartFox);
			menuBalloon.isCategoryMenu = true;
			menuBalloon.updated.add(updateMenuBalloon);
			_categoryBalloonEntity.add(menuBalloon);
			
			_textFormat	= new TextFormat();
			_textFormat.align 			= TextFormatAlign.CENTER;
			_textFormat.bold 			= true;
			_textFormat.font 			= "Billy Serif";
			_textFormat.size 			= 18;
			_textFormat.color 			= 0x000000;
			
			Display(_categoryBalloonEntity.get(Display)).visible = false;
			
			return _categoryBalloonEntity;
		}
		
		public function createMsgOptions():Entity
		{
			_msgOptionsBalloonEntity = new Entity();
			
			_msgOptionsBalloonEntity = EntityUtils.createSpatialEntity(_chat, _clip);
			var menuBalloon:MenuBalloon = new MenuBalloon(_chat.shellApi.smartFox);
			menuBalloon.isCategoryMenu = false;
			menuBalloon.updated.add(updateMsgMenuBalloon);
			_msgOptionsBalloonEntity.add(menuBalloon);
			
			_textFormat	= new TextFormat();
			_textFormat.align 			= TextFormatAlign.CENTER;
			_textFormat.bold 			= true;
			_textFormat.font 			= "Billy Serif";
			_textFormat.size 			= 18;
			_textFormat.color 			= 0x000000;
			
			Display(_msgOptionsBalloonEntity.get(Display)).visible = false;
			
			return _msgOptionsBalloonEntity;
		}
		
		private function updateMenuBalloon($menuBalloon:MenuBalloon):void
		{
			
			
			//expandBG();
			
			switch(_chat.state){
				case Chat.STATE_CHAT_CATEGORIES:
					
					if($menuBalloon.isCategoryMenu)
					{
						
						
						for(var c:int = 0; c < $menuBalloon.data.length; c++){
							if(c==1)
								trace("MenuBalloonCreator :: remove friend category")
							else
								_categoryRows.push(newRow(true,$menuBalloon.data[c].string, $menuBalloon.data[c].id));
						}
					}
					
					break;
			}
			
			//resize($menuBalloon.isCategoryMenu);
		}
		
		private function updateMsgMenuBalloon($menuBalloon:MenuBalloon):void
		{
			
			
			//expandBG();
			for each(var chatoption:Entity in _msgRows){
				_chat.removeEntity(chatoption);
			}
			_msgRows = new Vector.<Entity>();
			
			switch(_chat.state){
				case Chat.STATE_CHAT_MESSAGES:
					// generate options
					Display(_msgOptionsBalloonEntity.get(Display)).visible = true;
					Spatial(_msgOptionsBalloonEntity.get(Spatial)).x = _chat.shellApi.camera.viewportWidth *.6;
					_msgRows = new Vector.<Entity>();
					if(!$menuBalloon.isCategoryMenu)
					{
						for(var i:int = 0; i < $menuBalloon.data.length; i++){
							if($menuBalloon.data[i].string != "Want to be friends?")
							{
								_msgRows.push(newMsgRow(false,$menuBalloon.data[i].string, $menuBalloon.data[i].id));

							}
							// add divider
							//if(i > 0){
								//_msgDividers.push(newMsgDivider(Spatial(_msgRows[i].get(Spatial)).y - (Chat.CHAT_ROW_SPACING/2)));
							//}
						}
					}
					_chat._msgOptionsBalloon.get(Spatial).x = _chat.shellApi.camera.viewportWidth * 0.38;
					_chat._msgOptionsBalloon.get(Spatial).y = ((_chat.shellApi.camera.viewportHeight * 0.3));
					break;
			}
			
			//resize($menuBalloon.isCategoryMenu);
		}
		
		
		private function newRow(isCategory:Boolean, $string:String, $id:int, $button:Object = null):Entity
		{
			// create textfield
			var text:TextField = new TextField();
			text.width = Chat.CHAT_TEXT_WIDTH;
			text.height = 25;
			text.setTextFormat(_textFormat);
			text.defaultTextFormat = _textFormat;
			text.embedFonts 		= true;
			text.antiAliasType 		= AntiAliasType.NORMAL;
			text.autoSize			= TextFieldAutoSize.CENTER;
			text.wordWrap 			= true;
			text.multiline 			= true;
			text.maxChars 			= 0; // unlimited
			if($button){
				text.text = $button.label;
			} else {
				text.text = $string;
			}
			text.mouseEnabled = false;
			text.mouseWheelEnabled = false;
			text.x = - text.width * 0.5;

			// load button asset
			var entity:Entity = ButtonCreator.loadButtonEntity("ui/chat/chat_cat_option.swf", _chat, onCatRow, Display(_categoryBalloonEntity.get(Display)).displayObject, null, Command.create(createRow, text, $button), null, false);
			
			// consider type
			var type:int;
			
			// create row to hold data
			var row:MenuBalloonRow = new MenuBalloonRow($string, $id, _chat.state);
			entity.add(row);
			
			if($button){
				row.buttonHandler = $button.handler;
				row.buttonParam = $button.param;
			}
			
			// adjust spatial
			var option_height:Number = text.height + Chat.CHAT_TEXT_Y_BUFFER;
			var spatial:Spatial = new Spatial();
			spatial.x = 0;
			spatial.y = nextRowY();
			spatial.height = option_height;
			spatial.width = Chat.CHAT_ROW_WIDTH;
			entity.add(spatial);
			
			return entity;
		}
		private function newMsgRow(isCategory:Boolean, $string:String, $id:int, $button:Object = null):Entity
		{
			// create textfield
			var text:TextField = new TextField();
			text.width = Chat.CHAT_TEXT_WIDTH;
			text.height = 25;
			text.setTextFormat(_textFormat);
			text.defaultTextFormat = _textFormat;
			text.embedFonts 		= true;
			text.antiAliasType 		= AntiAliasType.NORMAL;
			text.autoSize			= TextFieldAutoSize.CENTER;
			text.wordWrap 			= true;
			text.multiline 			= true;
			text.maxChars 			= 0; // unlimited
			if($button){
				text.text = $button.label;
			} else {
				text.text = $string;
			}
			text.mouseEnabled = false;
			text.mouseWheelEnabled = false;
			text.x = - text.width * 0.5;
			
			// load button asset
			var entity:Entity = ButtonCreator.loadButtonEntity("ui/chat/chat_option.swf", _chat, onMsgRow, Display(_msgOptionsBalloonEntity.get(Display)).displayObject, null, Command.create(createMsgRow, text, $button), null, false);
			
			// consider type
			var type:int;
			
			// create row to hold data
			var row:MenuBalloonRow = new MenuBalloonRow($string, $id, _chat.state);
			entity.add(row);
			
			if($button){
				row.buttonHandler = $button.handler;
				row.buttonParam = $button.param;
			}
			
			// adjust spatial
			var option_height:Number = text.height + Chat.CHAT_TEXT_Y_BUFFER;
			var spatial:Spatial = new Spatial();
			spatial.x = 0;
			spatial.y = nextMsgRowY();
			spatial.height = option_height;
			spatial.width = Chat.CHAT_ROW_WIDTH;
			entity.add(spatial);
			
			return entity;
		}
		
		
		private function createRow(entity:Entity, text:TextField, $button:Object):void
		{
			var content:MovieClip = Display(entity.get(Display)).displayObject as MovieClip;
			content.gotoAndStop(0);

			// scale bg
			content.height = text.height + Chat.CHAT_TEXT_Y_BUFFER;
			
			// allign text to content's stage
			text.y = (content.height * 0.5) - (text.height * 0.5);
			
			// account for the scaling of the clip (from the spatial height adjustment)
			text.scaleY /= content.scaleY;
			text.y /= content.scaleY;
			text.scaleX /= content.scaleX;
			text.x /= content.scaleX;
			// add text to the content
			content.addChild(text);
			
			// show button graphic?
			if($button)
				content["button"].visible = true;
			
			// add entity's content to the _msgMenu
			Display(_categoryBalloonEntity.get(Display)).displayObject.addChild(content);
			
			// remove tooltip if chat isn't open when created
			if(!_chat.isOpen)
				entity.remove(ToolTipActive);
			
			// count option loaded
			_rowsLoaded++;
			if(_rowsLoaded >= _categoryRows.length){
				_chat.chatReady();
			}
		}
		private function MOVMessage(entity:Entity):void
		{
			var content:MovieClip = Display(entity.get(Display)).displayObject as MovieClip;
			content.gotoAndStop(1);
		}
		private function MOMessage(entity:Entity):void
		{
			var content:MovieClip = Display(entity.get(Display)).displayObject as MovieClip;
			content.gotoAndStop(0);
		}
		private function createMsgRow(entity:Entity, text:TextField, $button:Object):void
		{
			var content:MovieClip = Display(entity.get(Display)).displayObject as MovieClip;
			content.gotoAndStop(0);

			
			// scale bg
			content.height = text.height + Chat.CHAT_TEXT_Y_BUFFER;
			
			// allign text to content's stage
			text.y = (content.height * 0.5) - (text.height * 0.5);
			
			// account for the scaling of the clip (from the spatial height adjustment)
			text.scaleY /= content.scaleY;
			text.y /= content.scaleY;
			text.scaleX /= content.scaleX;
			text.x /= content.scaleX;
			
			// add text to the content
			content.addChild(text);
			
			// show button graphic?
			if($button)
				content["button"].visible = true;
			
			// add entity's content to the _msgMenu
			Display(_msgOptionsBalloonEntity.get(Display)).displayObject.addChild(content);
			
			// remove tooltip if chat isn't open when created
			if(!_chat.isOpen)
				entity.remove(ToolTipActive);
			
			// count option loaded
			_msgRowsLoaded++;
			if(_msgRowsLoaded >= _msgRows.length){
				_chat.chatReady();
			}
		}
		
		private function nextRowY():Number
		{
			var y:Number = Chat.CHAT_ROW_SPACING;
			for(var c:int = 0; c < _categoryRows.length; c++){
				y += Chat.CHAT_ROW_SPACING+Spatial(_categoryRows[c].get(Spatial)).height;
			}
			
			return y;
		}
		
		private function nextMsgRowY():Number
		{
			var y:Number = Chat.CHAT_ROW_SPACING;
			for(var c:int = 0; c < _msgRows.length; c++){
				y += Chat.CHAT_ROW_SPACING+Spatial(_msgRows[c].get(Spatial)).height;
			}
			
			return y;
		}
		
		private function newDivider($y:Number):Entity
		{
			var shape:Shape	= new Shape();
			shape.graphics.lineStyle(1,0x000000,1);
			shape.graphics.moveTo(Chat.CHAT_TEXT_WIDTH/-2, 0);
			shape.graphics.lineTo(Chat.CHAT_TEXT_WIDTH/2, 0);
			
			var line:DisplayObjectContainer = new Sprite();
			line.addChild(shape);
			
			// add line as a child
			Display(_categoryBalloonEntity.get(Display)).displayObject.addChild(line);
			
			// create and add entity
			var divider:Entity = EntityUtils.createSpatialEntity(_chat, line);
			Spatial(divider.get(Spatial)).x = 0;
			Spatial(divider.get(Spatial)).y = $y;
			
			return divider;
		}
		
		private function newMsgDivider($y:Number):Entity
		{
			var shape:Shape	= new Shape();
			shape.graphics.lineStyle(1,0x000000,1);
			shape.graphics.moveTo(Chat.CHAT_TEXT_WIDTH/-2, 0);
			shape.graphics.lineTo(Chat.CHAT_TEXT_WIDTH/2, 0);
			
			var line:DisplayObjectContainer = new Sprite();
			line.addChild(shape);
			
			// add line as a child
			Display(_msgOptionsBalloonEntity.get(Display)).displayObject.addChild(line);
			
			// create and add entity
			var divider:Entity = EntityUtils.createSpatialEntity(_chat, line);
			Spatial(divider.get(Spatial)).x = 0;
			Spatial(divider.get(Spatial)).y = $y;
			
			return divider;
		}
		
		private function resize(isCategory:Boolean):void
		{
			// resize the menu bg
			var height:Number = Chat.CHAT_ROW_SPACING+Chat.CHAT_BUBBLE_SHADOW_HEIGHT; // shadow height
			var background:DisplayObject;
			var bounds:Rectangle;
			// resize background
			if(isCategory)
			{
				for each(var entity:Entity in _categoryRows){
					height += Spatial(entity.get(Spatial)).height+(Chat.CHAT_ROW_SPACING);
				}
			}
			else
			{
				for each(var entity2:Entity in _msgRows){
					height += Spatial(entity2.get(Spatial)).height+(Chat.CHAT_ROW_SPACING);
				}
			}

			_msgMenuHeight = height;
		}
		
		public function reset():void{
			collapseBG();
			
			// reset options loaded
			_rowsLoaded = 0;
			_msgRowsLoaded = 0;
		}
		
		
		////////////////////////// handlers //////////////////////////
		
		private function onCatRow($rowEntity:Entity):void
		{
			var row:MenuBalloonRow = $rowEntity.get(MenuBalloonRow);

			_lastSubjectString = row.string;
			_chat.shellApi.track(Chat.TRACK_CHAT_SUBJECT, row.string);
			_chat.state = Chat.STATE_CHAT_MESSAGES;
					
			// get messages per selected category
			if(!row.reply){
				MenuBalloon(_chat._msgOptionsBalloon.get(MenuBalloon)).getMessages(row.id);
				
			} else {
				MenuBalloon(_chat._msgOptionsBalloon.get(MenuBalloon)).getReplies(row.id);
			}
		}
		
		private function onMsgRow($rowEntity:Entity):void
		{
			var row:MenuBalloonRow = $rowEntity.get(MenuBalloonRow);
			for each(var chatoption:Entity in _msgRows){
				_chat.removeEntity(chatoption);
			}
			_msgRows = new Vector.<Entity>();
			if(row.id >= 11 && row.id <= 16)// send off chat msg
			{
				if(row.id == 11)
				{
					//turn off friending for mobile (not supported currently)
					if(!PlatformUtils.isMobileOS)
					{
						_chat.SendLoginRequestObj( _chat._targetPlayer);
					}
					if(!_chat.shellApi.profileManager.active.isGuest)
						_chat.send(row);
				}
				else
					_chat.send(row);
			}
			else
				_chat.SendGlobal(row);
			
			// track string sent
			var trackString:String = row.string;
			if(trackString.length > 64){
				trackString = trackString.slice(0, 64);
			}
			
			_chat.shellApi.track(Chat.TRACK_CHAT_TEXT, trackString, _lastSubjectString);
			
			// run button handler if any
			if(row.buttonHandler){
				if(_chat.sfSceneGroup.scene[row.buttonHandler])
					_chat.sfSceneGroup.scene[row.buttonHandler](_chat.targetedPlayer, row.buttonParam);
			}
			reset();
			_chat.close();
		}
		
		///////////////////////// Friend Code ///////////////////////////////
		private function ClickFriendMessage():void
		{
			// if guest, then show message that yhou can't friend if game is not saved
			if (_chat.shellApi.profileManager.active.isGuest)
			{
				var sceneUIGroup:SceneUIGroup = _chat.sfSceneGroup.scene.groupManager.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup;
				sceneUIGroup.askForConfirmation(SceneUIGroup.CANT_FRIEND_IF_NOT_SAVED, sceneUIGroup.removeConfirm, sceneUIGroup.removeConfirm);
				return;
			}
			
			// change text on button
			//_friendButton.get(Display).displayObject.tLabel.text = "ADDING...";
			trace("MenuBalloonCreator :: ClickedFriendButton - ADDING");
			
			// track click with user name in form "npc:name"
			//_chat.shellApi.adManager.track(_NPCFriendCampaign, AdTrackingConstants.TRACKING_FRIEND_CLICKED, _NPCFriendUserName);
			
			// send message to server
			var vars:URLVariables = new URLVariables();
			// if browser or true mobile
			if ((PlatformUtils.inBrowser) || (AppConfig.mobile))
			{
				// set params to send to server
				vars.login = _chat.shellApi.profileManager.active.login;
				vars.pass_hash = _chat.shellApi.profileManager.active.pass_hash;
				vars.dbid = _chat.shellApi.profileManager.active.dbid;
				vars.logged_in = 1;
			}
			else
			{
				// otherwise use testing credentials
				// use testing user on xpop
				vars.login = "arcadefriend";
				vars.pass_hash = "827ccb0eea8a706c4c34a16891f84e7b";
				vars.dbid = 2;
				vars.logged_in = 0;
			}
			// add other params
			vars.favorite = 2;
			//vars.friend_login = _NPCFriendUserName;
			vars.method = 0;
			
			// make php call to server
			var connection:Connection = new Connection();
			connection.connect(_chat.shellApi.siteProxy.secureHost + "/friends/add_friend.php", vars, URLRequestMethod.POST, addFriendCallback, addFriendError);
		}
		
		// Friending code ================================================================================
		
		/**
		 * When friending callback is received from server 
		 * @param e
		 */
		private function addFriendCallback(e:Event):void
		{
			// hide all buttons
			//hideButtons();
			
			// parse data
			var return_vars:URLVariables = new URLVariables(e.target.data);
			// check answer
			switch (return_vars.answer)
			{
				case "ok": // if successful
					// send tracking call
					//_shellApi.adManager.track(_NPCFriendCampaign, AdTrackingConstants.TRACKING_ADD_FRIEND, _NPCFriendUserName);
					
					// update lso to show number of friends
					var lso:SharedObject = ProxyUtils.as2lso;
					if (lso.data)
					{
						if (lso.data.numFriends)
							lso.data.numFriends++;
						else
							lso.data.numFriends = 1;
						lso.flush();
					}
					break;
				
				case "item-already-there": // if NPC is already friend then display message saying so
					var sceneUIGroup:SceneUIGroup = _chat.sfSceneGroup.scene.groupManager.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup;
					sceneUIGroup.askForConfirmation(SceneUIGroup.ALREADY_FRIENDS, sceneUIGroup.removeConfirm, sceneUIGroup.removeConfirm);
					break;
				
				default: // if errors
					// possible errors: "no-such-user", "no-such-friend-login"
					// no-such-friend-login means that the NPC friend has not been setup on the server (such as xpop)
					// NPC friends on a server have a username in the form "npc:name" and password "npcfriend"
					trace("MenuBalloonCreator: AddFriendCallback Error: " + return_vars.answer);
					break;
			}
		}
		
		/**
		 * If error when calling add_friend 
		 * @param e
		 */
		private function addFriendError(e:IOErrorEvent):void
		{
			trace("AdManager.addFriendError: " + e.errorID)
		}
		
		////////////////////////// public methods //////////////////////////
		public function back():void{
			reset();
			MenuBalloon(_categoryBalloonEntity.get(MenuBalloon)).back();
		}
		
		public function clear():void
		{
			for each(var option:Entity in _categoryRows){
				_chat.removeEntity(option);
			}
		
			for each(var chatoption:Entity in _msgRows){
				_chat.removeEntity(chatoption);
			}
			
			_categoryRows = new Vector.<Entity>();
			_msgRows = new Vector.<Entity>();
		}
		
		public function expandBG():void
		{
		}
		
		public function collapseBG():void
		{
		}
		
		public function hideToolTips():void
		{
			for each(var entity:Entity in _categoryRows){
				entity.remove(ToolTipActive);
			}
		}
		
		public function showToolTips():void
		{
			for each(var entity:Entity in _categoryRows){
				entity.add(new ToolTipActive());
			}
		}
		
		public function get msgMenuHeight():Number{ return _msgMenuHeight };
		
		private var _categoryBalloonEntity:Entity;
		private var _msgOptionsBalloonEntity:Entity;
		//private var _bg:DisplayObject;
		
		private var _clip:MovieClip;
		private var _chat:Chat;
		private var _textFormat:TextFormat;
		
		private var _categoryRows:Vector.<Entity> = new Vector.<Entity>();
		private var _categoryDividers:Vector.<Entity> = new Vector.<Entity>();
		
		private var _msgRows:Vector.<Entity> = new Vector.<Entity>();
		private var _msgDividers:Vector.<Entity> = new Vector.<Entity>();
		
		private var _rowsLoaded:int;
		private var _msgRowsLoaded:int;
		
		private var _msgMenuHeight:Number;
		
		private var _lastSubjectString:String;
		
	}
}