package game.ui.multiplayer.chat
{
	import com.greensock.easing.Elastic;
	import com.poptropica.AppConfig;
	import com.smartfoxserver.v2.entities.User;
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	import com.smartfoxserver.v2.entities.data.SFSObject;
	import com.smartfoxserver.v2.requests.ExtensionRequest;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.SharedObject;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.UIView;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.entity.character.Character;
	import game.components.entity.character.Player;
	import game.components.entity.character.Talk;
	import game.components.multiplayer.chat.MenuBalloon;
	import game.components.multiplayer.chat.MenuBalloonRow;
	import game.components.multiplayer.chat.MsgBalloon;
	import game.components.smartFox.SFScenePlayer;
	import game.components.ui.ToolTipActive;
	import game.creators.entity.character.CharacterCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.creators.ui.WordBalloonCreator;
	import game.data.TimedEvent;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.display.BitmapWrapper;
	import game.data.ui.ToolTipType;
	import game.proxy.Connection;
	import game.scene.template.CharacterGroup;
	import game.scene.template.SFSceneGroup;
	import game.scene.template.SceneUIGroup;
	import game.ui.hud.Hud;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class Chat extends UIView
	{
		public static var GROUP_ID:String					 			= "chat";
		
		public static var CHAT_ROW_SPACING:int 			 				= 5;
		public static var CHAT_ROW_DEFAULT_HEIGHT:int 	 				= 12;
		public static var CHAT_ROW_WIDTH:int				 			= 210;
		public static var CHAT_TEXT_WIDTH:int				 			= 310;
		public static var CHAT_TEXT_Y_BUFFER:int             			= 12;
		public static var CHAT_BUBBLE_SHADOW_HEIGHT:Number   			= 6.5;
		
		public static var STATE_CHAT_CLOSED:int			 	 			= 0;
		public static var STATE_CHAT_CATEGORIES:int		 	 			= 1;
		public static var STATE_CHAT_MESSAGES:int			 			= 2;
		
		// brain tracking values
		public static const TRACK_CHATBUTTON_OPENED:String				= "ChatButtonClicked";
		public static const TRACK_CHATFRIEND_OPENED:String				= "ChatFriendClicked"
		public static const TRACK_CHAT_SUBJECT:String					= "ChatSubject";
		public static const TRACK_CHAT_TEXT:String						= "ChatText";
		
		public static const TRACK_EMOJI_OPENED:String					= "EmojiButtonClicked";
		public static const TRACK_EMOJI_SENT:String						= "EmojiSent";
		
		public static const CMD_GET_CHAT:String							= "C";
		public static const CMD_GET_MESSAGES:String						= "CM";
		public static const CMD_GET_REPLIES:String						= "CR";
		
		public static const KEY_CHAT_CATEGORIES:String			        = "CC";
		public static const KEY_CHAT_CATEGORY_ID:String        		    = "CC_ID";
		public static const KEY_CHAT_MESSAGE_ID:String        		    = "CM_ID";
		public static const KEY_CHAT_KEYWORDS:String					= "C_KW";
		public static const KEY_CHAT_MESSAGES:String					= "CMM";
		
		public static var EMOJI_COUNT:Number				   			= 21;
		
		public function Chat($sfSceneGroup:SFSceneGroup)
		{
			_sfSceneGroup = $sfSceneGroup;
			super();
			super.id = GROUP_ID;
		}
		
		override public function added():void
		{
			//shellApi.loadFile(shellApi.assetPrefix + "scenes/hub/arcade/chat/chat.swf", buildChat);
			shellApi.loadFile(shellApi.assetPrefix + "ui/chat/chat.swf", buildNewChat);
		}
		
		override public function destroy():void{
			// garbage collection
			
			chatOpen.removeAll();
			chatOpen = null;
			
			_lastSubjectString = null;
			
			_clip = null;
			
			_backgroundTint = null;
			_textFormat = null;
			_msgText = null;
			
			_targetLook = null;
			_hud = null;
			
			super.destroy();
		}
		
		private function buildChat(clip:MovieClip):void{
			
			_clip = clip;
			_sfSceneGroup.scene.overlayContainer.addChild(clip);
			
			_msgBalloonCreator = new MsgBalloonCreator(this, clip["msg_recieved"] as MovieClip);
			_categoryBalloonCreator = new MenuBalloonCreator(this, clip["msg_menu"] as MovieClip);
			
			// build UI balloons
			_msgBalloon = _msgBalloonCreator.create();
			_categoryBalloon = _categoryBalloonCreator.create();
			
			// create dummy avatars in portraits
			_chatCharGroup = new CharacterGroup();
			_chatCharGroup.id = "charCharGroup";
			_chatCharGroup.setupGroup(this);	
			
			// make player portrait
			var lookConverter:LookConverter = new LookConverter();
			var playerLook:LookData = _targetLook = lookConverter.lookDataFromPlayerLook(shellApi.profileManager.active.look);
			_playerPortrait = _chatCharGroup.createDummy("player", playerLook, "left", "", Display(_categoryBalloon.get(Display)).displayObject["portrait"]["avatarHolder"], this, null, true, NaN, CharacterCreator.TYPE_DUMMY);
			Character(_playerPortrait.get(Character)).costumizable = false;
			
			// make temp target portrait
			_targetPortrait = _chatCharGroup.createDummy("target", _targetLook, "right", "", Display(_msgBalloon.get(Display)).displayObject["portrait"]["avatarHolder"], this, null, true, NaN, CharacterCreator.TYPE_DUMMY);
			_targetPortrait.add(new Talk());
			Character(_targetPortrait.get(Character)).costumizable = false;
			
			// hide balloons
			Display(_msgBalloon.get(Display)).visible = false;
			Display(_categoryBalloon.get(Display)).visible = false;
			
			// create background
			_background = new Entity();
			var bgClip:MovieClip = new MovieClip();
			bgClip.graphics.beginFill(0x000000);
			bgClip.graphics.drawRect(0, 0, shellApi.viewportWidth, shellApi.viewportHeight);
			bgClip.graphics.endFill();
			
			_backgroundTint = super.convertToBitmap( bgClip );
			bgClip.alpha = .4;
			_sfSceneGroup.scene.overlayContainer.addChildAt(bgClip, 0);
			_background.add( new Display( bgClip ) );
			bgClip.visible = false;
			var interaction:Interaction = InteractionCreator.addToEntity( _background, [ InteractionCreator.CLICK ], bgClip );
			interaction.click.add( close );
			super.addEntity( _background );
			
			// get HUD
			var uiGroup:SceneUIGroup = _sfSceneGroup.scene.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup;
			_hud = uiGroup.hud as Hud;
			
			// create back / close buttons
			_closeButton = ButtonCreator.createButtonEntity(clip["closeButton"], this, onClose, null, null, null, false);
			_backButton = ButtonCreator.createButtonEntity(clip["backButton"], this, onBack, null, null, null, false);
			
			// position buttons
			var closeSpatial:Spatial = _closeButton.get(Spatial);
			closeSpatial.x = shellApi.camera.viewportWidth - (closeSpatial.width*0.6);
			closeSpatial.y = closeSpatial.height*0.6;
			
			var backSpatial:Spatial = _backButton.get(Spatial);
			backSpatial.x = closeSpatial.x - (backSpatial.width*0.6) - (closeSpatial.width*0.5);
			backSpatial.y = backSpatial.height*0.6;
			
			// hide buttons
			Display(_closeButton.get(Display)).visible = false;
			Display(_backButton .get(Display)).visible = false;
		}
		
		
		private function buildNewChat(clip:MovieClip):void{
			_clip = clip;
			_sfSceneGroup.objectRecieved.add(onObjectRecieved); 
			_sfSceneGroup.scene.overlayContainer.addChild(clip);
			
			_msgBalloonCreator = new MsgBalloonCreator(this, clip["msg_recieved"] as MovieClip);
			_categoryBalloonCreator = new MenuBalloonCreator(this, clip["cat_menu"] as MovieClip);
			
			// build UI balloons
			_msgBalloon = _msgBalloonCreator.create();
			_categoryBalloon = _categoryBalloonCreator.create();
			
			_msgOptionsBalloonCreator = new MenuBalloonCreator(this, clip["msg_menu"] as MovieClip, _msgOptionsBalloon);
			_msgOptionsBalloon = _msgOptionsBalloonCreator.createMsgOptions();
			
			_chatButton = ButtonCreator.createButtonEntity(clip["chatBtn"], this, ChatBtnClicked, null, null, null, false);			
			_emojiButton = ButtonCreator.createButtonEntity(clip["emojiBtn"], this, OpenEmojiMenu, null, null, null, false);
			
			_chatButton.get(Spatial).y = shellApi.camera.viewportHeight - 55;
			_emojiButton.get(Spatial).y = shellApi.camera.viewportHeight - 55;

			_chatButton.get(Spatial).x = 10;
			_emojiButton.get(Spatial).x = 60;
			
			_emojiBg = EntityUtils.createSpatialEntity(this,clip["emojiback"]);
			Display(_emojiBg.get(Display)).visible = false;
			
			_emojiContainer = clip["emojiContainer"];
			_emojiContainer.x = 30;
			_emojiContainer.y = shellApi.camera.viewportHeight - 235;
			_emojiBg.get(Spatial).y = shellApi.camera.viewportHeight - 235;
			_emojiBg.get(Spatial).x = 30;
			
			_emojiThoughtBubbleClip = clip["thoughtbubble"];
			
			// if suppressing icons in clubhouse, then hide
			if (_sfSceneGroup.suppressIconsOnInit)
			{
				showChatBtns(false);
			}
			
			// listen for hud closing and opening
			Hud(this.getGroupById(Hud.GROUP_ID)).openingHud.add(hudOpened);
			
			_emojis = new Array();
			_emojisDisplay = new Array();
			_emojisDisplayEnt = new Array();
			var emoji:Entity;
			for(var i:Number=0;i<EMOJI_COUNT;i++)
			{
				var x:Number = i+1;
				emoji = ButtonCreator.createButtonEntity(_emojiContainer["emoji"+x.toString()],this,SendEmojiObj,null, null, null, false);
				emoji.add(new Id("emoji"+x.toString()));
				Display(emoji.get(Display)).visible = false;
				emoji.remove(ToolTipActive);
				//Display(emojiDisp.get(Display)).visible = false;
				_emojis.insertAt(i,emoji);
				_emojisDisplay.insertAt(i,_emojiContainer["emoji"+x.toString()]);
				_emojisDisplayEnt.insertAt(i,_clip["demoji"+x.toString()]);
			}
			
			// create background
			_background = new Entity();
			var bgClip:MovieClip = new MovieClip();
			bgClip.graphics.beginFill(0x000000);
			bgClip.graphics.drawRect(0, 0, shellApi.viewportWidth, shellApi.viewportHeight);
			bgClip.graphics.endFill();
			
			_backgroundTint = super.convertToBitmap( bgClip );
			bgClip.alpha = .4;
			_sfSceneGroup.scene.overlayContainer.addChildAt(bgClip, 0);
			_background.add( new Display( bgClip ) );
			bgClip.visible = false;
			var interaction:Interaction = InteractionCreator.addToEntity( _background, [ InteractionCreator.CLICK ], bgClip );
			interaction.click.add( close );
			super.addEntity( _background );
			
			// get HUD
			var uiGroup:SceneUIGroup = _sfSceneGroup.scene.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup;
			_hud = uiGroup.hud as Hud;
			
			//Display(_msgOptionsBalloon.get(Display)).visible = true;
			_msgOptionsBalloon.get(Spatial).x = shellApi.camera.viewportWidth * 0.9;
			_msgOptionsBalloon.get(Spatial).y = ((shellApi.camera.viewportHeight * 0.6));			
		}
		// when hud closed then show buttons
		private function hudOpened(state:Boolean):void
		{
			showButton(_chatButton, !state);
			showButton(_emojiButton, !state);
		}
		// show/hide button
		private function showButton(btnEntity:Entity, state:Boolean):void
		{
			// set visibility
			btnEntity.get(Display).visible = state;
			
			// toggle tooltip
			showButtonTooltip(btnEntity, state);
		}
		// set button tooltip
		private function showButtonTooltip(btnEntity:Entity, state:Boolean, isSceneButton:Boolean = false, labelText:String = null):void
		{
			// enable/disable mouse if scene button (switch or door)
			if (isSceneButton)
			{
				btnEntity.get(Display).displayObject.mouseEnabled = state;
			}
			
			// set sleep
			Sleep(btnEntity.get(Sleep)).sleeping = !state;
			
			// enable/disable tooltip
			if (state)
			{
				if (!btnEntity.has(ToolTipActive))
				{
					ToolTipCreator.addToEntity(btnEntity, ToolTipType.CLICK, labelText);
				}
			}
			else
			{
				ToolTipCreator.removeFromEntity(btnEntity);
			}
		}
		
		public function chatReady():void{
			// make visible
			if(_chatOpen){
				if(MsgBalloon(_msgBalloon.get(MsgBalloon)).msg && MsgBalloon(_msgBalloon.get(MsgBalloon)).msg != ""){
					Display(_msgBalloon.get(Display)).visible = true;
				}
				Display(_categoryBalloon.get(Display)).visible = true;
			}
			
			// position elements
			_categoryBalloon.get(Spatial).x = shellApi.camera.viewportWidth * 0.15;
			_categoryBalloon.get(Spatial).y = 	shellApi.camera.viewportHeight - 244;
			_msgBalloon.get(Spatial).y = 	shellApi.camera.viewportHeight - 244;
		}
		
		public function OpenNewChat():void{
			this.state = STATE_CHAT_CATEGORIES;
			
			// dim background
			EntityUtils.getDisplayObject(_background).visible = true;
			
			// populate last message from the selected player
			var msg:String;
			
			if(msg != null && msg != ""){
				// show last message bubble
				Display(_msgBalloon.get(Display)).visible = true;
				MsgBalloon(_msgBalloon.get(MsgBalloon)).msg = msg;
				
			} else {
				MsgBalloon(_msgBalloon.get(MsgBalloon)).msg = null;
			}
			
			// reset data
			MenuBalloon(_categoryBalloon.get(MenuBalloon)).getCategories();
			
			chatOpen.dispatch(true);
			_hud.show(false);
			
			// brain track
			shellApi.track(TRACK_CHATBUTTON_OPENED, shellApi.sceneName);
			
			// show tooltips
			if(!_chatOpen){
				_msgOptionsBalloonCreator.showToolTips();
				_chatOpen = true;
			}
			
			// send do_not_disturb state to other players
			var obj:ISFSObject = new SFSObject();
			obj.putUtfString(SFSceneGroup.KEY_ACTION_TYPE, SFSceneGroup.TYPE_PLAYER_THINK);
			obj.putInt(SFSceneGroup.KEY_TARGET_USER_ID, SFScenePlayer(_sfSceneGroup.mySFPlayer.get(SFScenePlayer)).user.id);
			shellApi.smartFox.send(new ExtensionRequest(SFSceneGroup.CMD_PLAYERACTION, _sfSceneGroup.stampObj(obj), shellApi.smartFox.lastJoinedRoom));
			
			// play sound
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+"GUI_onClick.mp3");
		}
		
		
		public function OpenFriendChat(targetPlayer:Entity):void{
			this.state = STATE_CHAT_MESSAGES;
			_targetPlayer = targetPlayer;
			var sfPlayer:SFScenePlayer = targetPlayer.get(SFScenePlayer);
			MsgBalloon(_msgBalloon.get(MsgBalloon)).sfPlayer = sfPlayer;
			// dim background
			EntityUtils.getDisplayObject(_background).visible = true;
			
			// populate last message from the selected player
			var msg:String;
			
			// get messages per selected category
			Display(_msgOptionsBalloon.get(Display)).visible = true
			MenuBalloon(_msgOptionsBalloon.get(MenuBalloon)).getMessages(2,PlatformUtils.isMobileOS);
			
			chatOpen.dispatch(true);
			_hud.show(false);
			
			// brain track
			shellApi.track(TRACK_CHATFRIEND_OPENED, shellApi.sceneName);
			
			// show tooltips
			if(!_chatOpen){
				_msgOptionsBalloonCreator.showToolTips();
				_chatOpen = true;
			}
			
			// send do_not_disturb state to other players
			var obj:ISFSObject = new SFSObject();
			obj.putUtfString(SFSceneGroup.KEY_ACTION_TYPE, SFSceneGroup.TYPE_PLAYER_THINK);
			obj.putInt(SFSceneGroup.KEY_TARGET_USER_ID, SFScenePlayer(_sfSceneGroup.mySFPlayer.get(SFScenePlayer)).user.id);
			shellApi.smartFox.send(new ExtensionRequest(SFSceneGroup.CMD_PLAYERACTION, _sfSceneGroup.stampObj(obj), shellApi.smartFox.lastJoinedRoom));
			
			// play sound
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+"GUI_onClick.mp3");
		}
		
		///////////////////////// Friend Code ///////////////////////////////
		private function AddFriend(friend_login:String):void
		{
			// if guest, then show message that yhou can't friend if game is not saved
			if (shellApi.profileManager.active.isGuest)
			{
				var sceneUIGroup:SceneUIGroup = _sfSceneGroup.scene.groupManager.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup;
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
				vars.login = shellApi.profileManager.active.login;
				vars.pass_hash = shellApi.profileManager.active.pass_hash;
				vars.dbid = shellApi.profileManager.active.dbid;
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
			vars.friend_login = friend_login;
			vars.method = 0;
			
			// make php call to server
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/friends/add_friend.php", vars, URLRequestMethod.POST, addFriendCallback, addFriendError);
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
					var sceneUIGroup:SceneUIGroup = _sfSceneGroup.scene.groupManager.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup;
					sceneUIGroup.askForConfirmation("Friend added successfully.", sceneUIGroup.removeConfirm, sceneUIGroup.removeConfirm);
					shellApi.logWWW("Chat :: addFriendCallback - add friend - OK");
					break;
				
				case "item-already-there": // if NPC is already friend then display message saying so
					sceneUIGroup = _sfSceneGroup.scene.groupManager.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup;
					sceneUIGroup.askForConfirmation(SceneUIGroup.ALREADY_FRIENDS, sceneUIGroup.removeConfirm, sceneUIGroup.removeConfirm);
					shellApi.logWWW("Chat :: addFriendCallback - add friend - Already Friends");
					break;
				
				default: // if errors
					// possible errors: "no-such-user", "no-such-friend-login"
					// no-such-friend-login means that the NPC friend has not been setup on the server (such as xpop)
					// NPC friends on a server have a username in the form "npc:name" and password "npcfriend"
					trace("MenuBalloonCreator: AddFriendCallback Error: " + return_vars.answer);
					shellApi.logWWW("Chat :: addFriendCallback - default error" + return_vars.answer);
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
			shellApi.logWWW("AdManager.addFriendError: " + e.errorID);
		}
		/////////////////////////////////////////////////////////////////////////
		
		public function openChat($player:Entity):void{
			this.state = STATE_CHAT_CATEGORIES;
			
			_targetedPlayer = $player;
			
			// dim background
			EntityUtils.getDisplayObject(_background).visible = true;
			var sfPlayer:SFScenePlayer = $player.get(SFScenePlayer);
			
			MsgBalloon(_msgBalloon.get(MsgBalloon)).sfPlayer = sfPlayer;
			
			// update look data for selected player portrait
			SkinUtils.removeLook(_targetPortrait, _targetLook); // reset look (so it doesn't merge with the last)
			_targetLook = SkinUtils.getLook($player);
			SkinUtils.applyLook(_targetPortrait, _targetLook);
			
			// populate last message from the selected player
			var msg:String;
			
			if(sfPlayer.last_msg_obj)
				msg = sfPlayer.last_msg_obj.getUtfString("chat_message");
			
			if(msg != null && msg != ""){
				// show last message bubble
				Display(_msgBalloon.get(Display)).visible = true;
				MsgBalloon(_msgBalloon.get(MsgBalloon)).msg = msg;
				
				// play portrait avatar talk animation
				var time:Number = WordBalloonCreator.getDialogTime(msg, super.shellApi.profileManager.active.dialogSpeed);
				Talk(_targetPortrait.get(Talk)).isStart = true;
				SceneUtil.addTimedEvent(this, new TimedEvent(time, 1, stopTalkAni));
			} else {
				MsgBalloon(_msgBalloon.get(MsgBalloon)).msg = null;
			}
			
			// reset data
			MenuBalloon(_categoryBalloon.get(MenuBalloon)).getCategories();
			
			chatOpen.dispatch(true);
			_hud.show(false);
			
			// brain track
			shellApi.track(TRACK_CHATFRIEND_OPENED, shellApi.sceneName);
			
			// show tooltips
			if(!_chatOpen){
				_categoryBalloonCreator.showToolTips();
				_chatOpen = true;
			}
			
			// show close
			Display(_closeButton.get(Display)).visible = true;
			
			// send do_not_disturb state to other players
			var obj:ISFSObject = new SFSObject();
			obj.putUtfString(SFSceneGroup.KEY_ACTION_TYPE, SFSceneGroup.TYPE_PLAYER_THINK);
			obj.putInt(SFSceneGroup.KEY_TARGET_USER_ID, SFScenePlayer(_sfSceneGroup.mySFPlayer.get(SFScenePlayer)).user.id);
			shellApi.smartFox.send(new ExtensionRequest(SFSceneGroup.CMD_PLAYERACTION, _sfSceneGroup.stampObj(obj), shellApi.smartFox.lastJoinedRoom));
			
			// play sound
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+"GUI_onClick.mp3");
		}
		
		public function send($row:MenuBalloonRow):void{
			var user:User = MsgBalloon(_msgBalloon.get(MsgBalloon)).sfPlayer.user;
			
			var obj:ISFSObject = new SFSObject();
			obj.putInt(SFSceneGroup.KEY_TARGET_USER_ID, user.id);
			obj.putUtfString(SFSceneGroup.KEY_ACTION_TYPE, SFSceneGroup.TYPE_PLAYER_CHAT);
			obj.putInt(KEY_CHAT_MESSAGE_ID, $row.id);
			
			shellApi.smartFox.send(new ExtensionRequest(SFSceneGroup.CMD_PLAYERACTION, _sfSceneGroup.stampObj(obj), shellApi.smartFox.lastJoinedRoom));
		}
		
		public function SendGlobal($row:MenuBalloonRow):void{
			
			trace("Chat :: SendGlobal :: Start");
			for(var i:Number=0;i<_sfSceneGroup.allSFPlayers().length;i++)
			{
				var user:User = _sfSceneGroup.allSFPlayers()[i].get(SFScenePlayer).user;
				var obj:ISFSObject = new SFSObject();
				obj.putInt(SFSceneGroup.KEY_TARGET_USER_ID, user.id);
				obj.putUtfString(SFSceneGroup.KEY_ACTION_TYPE, SFSceneGroup.TYPE_PLAYER_CHAT);
				obj.putInt(KEY_CHAT_MESSAGE_ID, $row.id);
				
				shellApi.smartFox.send(new ExtensionRequest(SFSceneGroup.CMD_PLAYERACTION, _sfSceneGroup.stampObj(obj), shellApi.smartFox.lastJoinedRoom));
			}
			
			trace("Chat :: SendGlobal :: End");

		}
		
		
		private function centerBalloons():void{
			// normalize scales
			var msg_spatial:Spatial = _msgBalloon.get(Spatial);
			msg_spatial.scaleX = 1;
			msg_spatial.scaleY = 1;
			
			var menu_spatial:Spatial = _categoryBalloon.get(Spatial);
			menu_spatial.scaleX = 1;
			menu_spatial.scaleY = 1;
			
			// get center points
			var centerPoints:Vector.<Point> = balloonCenterPoints();
			
			if(PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_LOW){
				// tween the balloons out to the center
				TweenUtils.entityTo(_msgBalloon, Spatial, 1, {x:centerPoints[0].x, y:centerPoints[0].y, scale:1, ease:Elastic.easeOut});
				TweenUtils.entityTo(_categoryBalloon, Spatial, 1.2, {x:centerPoints[1].x, y:centerPoints[1].y, scale:1, ease:Elastic.easeOut});
			} else {
				// position balloons to center instantly
				msg_spatial.x = centerPoints[0].x;
				msg_spatial.y = centerPoints[0].y;
				menu_spatial.x = centerPoints[1].x;
				menu_spatial.y = centerPoints[1].y;	
			}
		}
		
		private function balloonsFromTarget($entity:Entity):void{
			// normalize scales
			var msg_spatial:Spatial = _msgBalloon.get(Spatial);
			msg_spatial.scaleX = 1;
			msg_spatial.scaleY = 1;
			
			var menu_spatial:Spatial = _categoryBalloon.get(Spatial);
			menu_spatial.scaleX = 1;
			menu_spatial.scaleY = 1;
			
			// get center points
			var centerPoints:Vector.<Point> = balloonCenterPoints();
			
			if(PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_LOW){
				// get position around the target
				var spatial:Spatial = $entity.get(Spatial);
				var targetPoints:Vector.<Point> = balloonCenterPoints(new Point(spatial.x, spatial.y));
				targetPoints[0] = DisplayUtils.localToLocalPoint(targetPoints[0], _sfSceneGroup.scene.hitContainer, _sfSceneGroup.scene.overlayContainer);
				targetPoints[1] = DisplayUtils.localToLocalPoint(targetPoints[1], _sfSceneGroup.scene.hitContainer, _sfSceneGroup.scene.overlayContainer);
				
				// interpolate
				targetPoints[0] = Point.interpolate(targetPoints[0], centerPoints[0], 0.5);
				targetPoints[1] = Point.interpolate(targetPoints[1], centerPoints[1], 0.5);
				
				// position balloons before tween
				msg_spatial.x = targetPoints[0].x;
				msg_spatial.y = targetPoints[0].y;
				menu_spatial.x = targetPoints[1].x;
				menu_spatial.y = targetPoints[1].y;
				
				// scale balloons before tween
				msg_spatial.scaleX = 0.8;
				msg_spatial.scaleY = 0.8;
				menu_spatial.scaleX = 0.8;
				menu_spatial.scaleY = 0.8;
				
				// tween the balloons out to the center
				TweenUtils.entityTo(_msgBalloon, Spatial, 1, {x:centerPoints[0].x, y:centerPoints[0].y, scale:1, ease:Elastic.easeOut});
				TweenUtils.entityTo(_categoryBalloon, Spatial, 1.2, {x:centerPoints[1].x, y:centerPoints[1].y, scale:1, ease:Elastic.easeOut});
			} else {
				// move balloons to the center
				msg_spatial.x = centerPoints[0].x;
				msg_spatial.y = centerPoints[0].y;		
				menu_spatial.x = centerPoints[1].x;
				menu_spatial.y = centerPoints[1].y;
			}
		}
		
		private function balloonCenterPoints($point:Point = null):Vector.<Point>{
			var points:Vector.<Point> = new Vector.<Point>();
			
			var msg_spatial:Spatial = _msgBalloon.get(Spatial);
			var menu_spatial:Spatial = new Spatial();
			menu_spatial.height = _msgOptionsBalloonCreator.msgMenuHeight; // PATCH: _menuBalloon's scaleY was getting changed after -- squeezing the menu (unknown why)
			//var menu_spatial:Spatial = _menuBalloon.get(Spatial); 
			
			var totalHeight:Number = (menu_spatial.height / menu_spatial.scaleY) + (msg_spatial.height / msg_spatial.scaleY);
			
			var msg_point:Point = new Point();
			var menu_point:Point = new Point();
			
			var msg_height:Number = (Display(_msgBalloon.get(Display)).displayObject["bg"].height)*msg_spatial.scaleY;
			
			if(!$point){
				if(MsgBalloon(_msgBalloon.get(MsgBalloon)).msg && MsgBalloon(_msgBalloon.get(MsgBalloon)).msg != ""){
					// center both balloons
					msg_point.x = shellApi.camera.viewportWidth * 0.2;
					msg_point.y = ((shellApi.camera.viewportHeight * 0.8) - msg_height) - (menu_spatial.height*0.4);
					menu_point.x = shellApi.camera.viewportWidth * 0.2;
					menu_point.y = (shellApi.camera.viewportHeight * 0.6) - (menu_spatial.height*0.4);
				} else {
					// only center the menu balloon
					msg_point.x = menu_point.x = shellApi.camera.viewportWidth * 0.2;
					msg_point.y = menu_point.y = ((shellApi.camera.viewportHeight * 0.6) - msg_height) - (menu_spatial.height*0.4);
				}
			} else {
				// come from target
				msg_point.x = $point.x;
				msg_point.y = $point.y - msg_height - (menu_spatial.height * 0.5);
				// come from player
				menu_point.x = $point.x;
				menu_point.y = $point.y - menu_spatial.height*0.5;
			}
			
			points[0] = msg_point;
			points[1] = menu_point;
			
			return points;
		}
		private function CloseChat(ignoreHud:Boolean = false):void
		{
			if (_background != null)
			{
				EntityUtils.getDisplayObject(_background).visible = false;
			}
			this.state = STATE_CHAT_CLOSED;
			_chatOpen = false;
			
			Display(_msgBalloon.get(Display)).visible = false;
			Display(_categoryBalloon.get(Display)).visible = false;
			Display(_msgOptionsBalloon.get(Display)).visible = false;
			// clear current menuOption entities
			_categoryBalloonCreator.hideToolTips();
			//_categoryBalloonCreator.reset();
			_categoryBalloonCreator.clear();
			_msgOptionsBalloonCreator.hideToolTips();
			
			chatOpen.dispatch(false);
			if ((!_emojiOpen) && (_hud != null))
			{
				_hud.show();
			}
			// send cancel do_not_disturb state to other players
			var obj:ISFSObject = new SFSObject();
			obj.putUtfString(SFSceneGroup.KEY_ACTION_TYPE, SFSceneGroup.TYPE_PLAYER_CANCEL);
			obj.putInt(SFSceneGroup.KEY_TARGET_USER_ID, SFScenePlayer(_sfSceneGroup.mySFPlayer.get(SFScenePlayer)).user.id);
			shellApi.smartFox.send(new ExtensionRequest(SFSceneGroup.CMD_PLAYERACTION, _sfSceneGroup.stampObj(obj), shellApi.smartFox.lastJoinedRoom));
		}
		
		private function CloseEmoji(ignoreHud:Boolean = false):void
		{
			EntityUtils.getDisplayObject(_background).visible = false;
			Display(_emojiBg.get(Display)).visible = false;
			for(var i:Number=0;i<EMOJI_COUNT;i++)
			{
				Display(_emojis[i].get(Display)).visible = false;
				_emojis[i].remove(ToolTipActive);
			}
			if (!_chatOpen)
				_hud.show();
			_emojiOpen = false;
		}
		public function close(ignoreHud:Boolean = false):void
		{
			if(_emojiOpen)
			{
				CloseEmoji(ignoreHud);
			}
			else
			{	
				CloseChat(ignoreHud);
			}
		}
		////////////////////////////////////////// EMOJI ///////////////////////////////////////////////////
		private function onObjectRecieved(obj:Object, whoSentIt:Entity):void
		{
			trace(" <--- Recieved an object from server");
			trace(obj);
			if(obj.emojiID)
				SendEmoji(whoSentIt,obj.emojiID);
			if(!PlatformUtils.isMobileOS)
			{
				if(obj.loginRequest)
					//AskToFriend(obj);
				if(obj.RequestedPlayerIsGuest)
				{
					//var sceneUIGroup:SceneUIGroup = _sfSceneGroup.scene.groupManager.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup;
					//sceneUIGroup.askForConfirmation("User is not registered.",sceneUIGroup.removeConfirm, sceneUIGroup.removeConfirm);
				}
				if(obj.loginInfo)
				{
					if(obj.isGuest == true || obj.loginInfo == "guest")
					{
						//sceneUIGroup = _sfSceneGroup.scene.groupManager.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup;
						//sceneUIGroup.askForConfirmation("User is not registered.",sceneUIGroup.removeConfirm, sceneUIGroup.removeConfirm);
	
					}
					else
					{
						//AddFriend(obj.loginInfo);
					}
				}
			}

			
			
		}
		
		public function SendLoginRequestObj(targetedPlayer:Entity):void
		{
			
			//if guest, can't friend
			if (shellApi.profileManager.active.isGuest)
			{
				var sceneUIGroup:SceneUIGroup = _sfSceneGroup.scene.groupManager.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup;
				sceneUIGroup.askForConfirmation(SceneUIGroup.CANT_FRIEND_IF_NOT_SAVED,sceneUIGroup.removeConfirm, sceneUIGroup.removeConfirm);
			}
			else
			{
				//var login:String = shellApi.profileManager.active.login;
				trace(" ---> Sending object to the server. login reuest to entity");
				var sfSceneGroup:SFSceneGroup = getGroupById(SFSceneGroup.GROUP_ID) as SFSceneGroup;
				var obj:Object = new Object();
				obj.loginRequest = "loginRequest";
				var username:String = shellApi.profileManager.active.avatarName;
				obj.username = username;
				obj.whoSentIt = sfSceneGroup.mySFPlayer;
				obj.login = shellApi.profileManager.active.login;
				sfSceneGroup.shareObject(obj,targetedPlayer);
				//CloseEmoji();
				//_adManager.track(super.adData.campaign_name, AdTrackingConstants.TRACKING_CLICK_ROOM_TRIGGER);
			}
		}
		public function SendLoginObj(object:Object):void
		{
			if(object.isGuest == true || object.loginInfo == "guest")
			{
				//adding popup here caused spam to reg users
				
			}
			else
			{
				AddFriend(object.login);
				var login:String = shellApi.profileManager.active.login;
				trace(" ---> Sending object to the server. login id: " + login);
				var sfSceneGroup:SFSceneGroup = getGroupById(SFSceneGroup.GROUP_ID) as SFSceneGroup;
				var obj:Object = new Object();
				obj.loginInfo = login;
				sfSceneGroup.shareObject(obj,object.whoSentIt);
				//CloseEmoji();
				//_adManager.track(super.adData.campaign_name, AdTrackingConstants.TRACKING_CLICK_ROOM_TRIGGER);
			}
		}
		public function AskToFriend(object:Object):void
		{
			if (shellApi.profileManager.active.isGuest)
			{
				object.isGuest = true;
				//var sceneUIGroup:SceneUIGroup = _sfSceneGroup.scene.groupManager.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup;
				//sceneUIGroup.askForConfirmation(SceneUIGroup.CANT_FRIEND_IF_NOT_SAVED, sceneUIGroup.removeConfirm, sceneUIGroup.removeConfirm);
				//SEND BACK GUEST OBJECT
				var sfSceneGroup:SFSceneGroup = getGroupById(SFSceneGroup.GROUP_ID) as SFSceneGroup;
				var obj:Object = new Object();
				obj.RequestedPlayerIsGuest = true;
				sfSceneGroup.shareObject(obj,object.whoSentIt);
				
				
			}
			else
			{
				var sceneUIGroup:SceneUIGroup = _sfSceneGroup.scene.groupManager.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup;
				sceneUIGroup.askForConfirmation("Would you like to be friends with: " + object.username, Command.create(SendLoginObj, object), sceneUIGroup.removeConfirm);
			}
		}
		private function SendEmojiObj(button:Entity):void
		{
			
			var id:String = Id(button.get(Id)).id
			trace(" ---> Sending object to the server. emoji id: " + id);
			shellApi.track(TRACK_EMOJI_SENT, id);
			var sfSceneGroup:SFSceneGroup = getGroupById(SFSceneGroup.GROUP_ID) as SFSceneGroup;
			var obj:Object = new Object();
			obj.sceneFunction = SendEmoji;
			obj.emojiID = id;
			sfSceneGroup.shareObject(obj);
			var slot:Number = Number(id.substr(5));
			
			var bubbledup:Sprite = BitmapUtils.createBitmapSprite(_emojiThoughtBubbleClip);
			var emojidup:Sprite = BitmapUtils.createBitmapSprite(_emojisDisplayEnt[slot-1]);
			
			var emojiThoughtBubble:Entity = EntityUtils.createSpatialEntity(shellApi.currentScene,bubbledup,Display(shellApi.player.get(Display)).container);
			EntityUtils.followTarget(emojiThoughtBubble,shellApi.player,1,new Point(20,-150));
			
			var emoji:Entity = EntityUtils.createSpatialEntity(shellApi.currentScene,emojidup,Display(shellApi.player.get(Display)).container);
			EntityUtils.followTarget(emoji,shellApi.player,1,new Point(55,-115));
			
			SceneUtil.addTimedEvent( shellApi.currentScene, new TimedEvent( 3, 1, Command.create( removeEmoji, emoji, emojiThoughtBubble)));
			emoji.get(Display).visible = true;
			
			
			CloseEmoji();
			//_adManager.track(super.adData.campaign_name, AdTrackingConstants.TRACKING_CLICK_ROOM_TRIGGER);
		}
		private function duplicateDisplayObject(target:DisplayObject):DisplayObject {
			// create duplicate\
			var targetClass:Class = Object(target).constructor;
			var duplicate:DisplayObject = new targetClass();
			return duplicate;
		}
		public function showChatBtns(state:Boolean):void
		{
			// make sure buttons exist
			if (_chatButton != null)
			{
				setButton(_chatButton, state);
				setButton(_emojiButton, state);
			}
			if (!state)
			{
				close(true);
			}
		}
		
		// set button state
		private function setButton(btn:Entity, state:Boolean):void
		{
			// set visibility
			btn.get(Display).visible = state;
			
			// set sleep
			Sleep(btn.get(Sleep)).sleeping = !state;
			
			// toggle tooltip
			if (state)
			{
				btn.add(new ToolTipActive());
			}
			else
			{
				btn.remove(ToolTipActive);
			}
		}
		
		private function SendEmoji(whoSentIt:Entity,emojiID:String):void{
			
			trace("Chat :: Recieved Emoji with id of: " + emojiID.toString());
			var slot:Number = Number(emojiID.substr(5));
			
			var bubbledup:Sprite = BitmapUtils.createBitmapSprite(_emojiThoughtBubbleClip);
			var emojidup:Sprite = BitmapUtils.createBitmapSprite(_emojisDisplayEnt[slot-1]);
			
			
			var emojiThoughtBubble:Entity = EntityUtils.createSpatialEntity(shellApi.currentScene,bubbledup,Display(whoSentIt.get(Display)).container);
			EntityUtils.followTarget(emojiThoughtBubble,whoSentIt,1,new Point(20,-150));
			var emoji:Entity = EntityUtils.createSpatialEntity(shellApi.currentScene,emojidup,Display(whoSentIt.get(Display)).container);
			EntityUtils.followTarget(emoji,whoSentIt,1,new Point(55,-115));
			
			SceneUtil.addTimedEvent( shellApi.currentScene, new TimedEvent( 3, 1, Command.create( removeEmoji, emoji,emojiThoughtBubble)));
			emoji.get(Display).visible = true;
		}
		private function removeEmoji(emoji:Entity,emojiThoughtBubble:Entity):void
		{
			shellApi.currentScene.removeEntity(emoji);
			shellApi.currentScene.removeEntity(emojiThoughtBubble);
		}
		//////////////////////////////////////////  Handlers ///////////////////////////////////////////////
		private function ChatBtnClicked($button:Entity):void
		{
			if(!_chatOpen)
			{
				if(_emojiOpen)
					CloseEmoji();
				OpenNewChat();
			}
		}
		private function OpenEmojiMenu($button:Entity):void
		{
			if(!_emojiOpen)
			{
				if(_chatOpen)
				{
					CloseChat();	
				}
				
				EntityUtils.getDisplayObject(_background).visible = true;
				Display(_emojiBg.get(Display)).visible = true;
				for(var i:Number=0;i<EMOJI_COUNT;i++)
				{
					Display(_emojis[i].get(Display)).visible = true;
					_emojis[i].add(new ToolTipActive());
				}
				_hud.show(false);
				_emojiOpen = true;
				shellApi.track(TRACK_EMOJI_OPENED, shellApi.sceneName);
			}
		}
		
		private function onClose($button:Entity):void
		{
			// play close sound
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+"ui_close_cancel.mp3");
			close();
		}
		
		private function onBack($button:Entity):void
		{
			this.state = STATE_CHAT_CATEGORIES;
			Display(_backButton.get(Display)).visible = false;
			_categoryBalloonCreator.back();
		}
		
		private function stopTalkAni():void{
			var talk:Talk = _targetPortrait.get(Talk);
			if( talk != null )
			{
				talk.isEnd = true;
			}
		}
		
		public function get msgReceived():Entity{ return _msgBalloon };
		public function get msgMenu():Entity{ return _categoryBalloon };
		public function get isOpen():Boolean{ return _chatOpen };
		public function get backButton():Entity{ return _backButton };
		public function get sfSceneGroup():SFSceneGroup{ return _sfSceneGroup };
		public function get targetedPlayer():Entity{ return _targetedPlayer };
		
		public var chatOpen:Signal = new Signal(Boolean);
		public var state:int;
		
		public var _targetedPlayer:Entity;
		
		// for tracking
		private var _lastSubjectString:String;
		
		private var _optionsLoaded:int = 0;
		
		private var _msgBalloon:Entity;
		public var _categoryBalloon:Entity;
		public var _msgOptionsBalloon:Entity;
		
		private var _msgBalloonCreator:MsgBalloonCreator;
		private var _categoryBalloonCreator:MenuBalloonCreator;
		private var _msgOptionsBalloonCreator:MenuBalloonCreator;
		
		
		private var _clip:MovieClip;
		
		private var _sfSceneGroup:SFSceneGroup;
		private var _background:Entity;
		
		private var _backgroundTint:BitmapWrapper;
		private var _textFormat:TextFormat;
		private var _msgText:TextField;
		
		private var _chatCharGroup:CharacterGroup;
		private var _targetPortrait:Entity;
		private var _playerPortrait:Entity;
		private var _targetLook:LookData;
		private var _hud:Hud;
		
		private var _backButton:Entity;
		private var _closeButton:Entity;
		
		private var _chatOpen:Boolean;
		private var _emojiOpen:Boolean;
		public var _targetPlayer:Entity;
		
		private var _chatButton:Entity;
		private var _emojiButton:Entity;
		private var _emojiBg:Entity;
		private var _emojis:Array;
		private var _emojisDisplay:Array;
		private var _emojisDisplayEnt:Array;
		private var _emojiThoughtBubble:Entity;
		private var _emojiThoughtBubbleClip:MovieClip;
		private var _emojiContainer:MovieClip;
		
	}
}