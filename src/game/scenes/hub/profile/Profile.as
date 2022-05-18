package game.scenes.hub.profile
{
	import com.adobe.utils.DictionaryUtil;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.entity.character.part.eye.Eyes;
	import game.components.timeline.Timeline;
	import game.components.ui.Cursor;
	import game.creators.entity.character.CharacterCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.display.BitmapWrapper;
	import game.data.profile.ProfileData;
	import game.data.ui.ToolTipType;
	import game.managers.SceneManager;
	import game.proxy.Connection;
	import game.scene.template.CharacterGroup;
	import game.scene.template.GameScene;
	import game.scenes.clubhouse.clubhouse.Clubhouse;
	import game.scenes.hub.profile.groups.PhotoBoardGroup;
	import game.scenes.hub.profile.popups.ChatPopup;
	import game.scenes.hub.profile.popups.MoodPopup;
	import game.scenes.hub.profile.popups.PhotoBoardPopup;
	import game.scenes.hub.profile.popups.ProfileMemberPopup;
	import game.scenes.hub.profile.popups.StickerWallPopup;
	import game.scenes.hub.town.Town;
	import game.systems.entity.EyeSystem;
	import game.systems.motion.DraggableSystem;
	import game.systems.specialAbility.SpecialAbilityControlSystem;
	import game.systems.ui.SliderSystem;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	import game.util.EntityUtils;
	import game.util.GridAlignment;
	import game.util.PlatformUtils;
	import game.util.SkinUtils;
	import game.util.TextUtils;
	
	public class Profile extends GameScene
	{
		//tracking constants
		private const TRACK_CLICK_MOOD_ICON:String = "Open";
		private const TRACK_CLICK_LIKE_BTN:String = "Like";
		private const TRACK_CLICK_CLUBHOUSE_BTN:String = "ClickClubhouse";
		private const TRACK_CLICK_SETTINGS_BTN:String = "Open";
		private const TRACK_CLICK_CHAT_BTN:String = "ClickSpeech";
		private const TRACK_CLICK_MOOD:String = "ClickMood";
		//tracking - is on player's profile or visiting another profile
		public var selfOrFriend:String;
		
		private var photoBoard:PhotoBoardGroup;
		private var photos:Array;
		private var numPhotots:int;
		private const MAX_PHOTOS:int = 6;
		
		private var _interactive:MovieClip;
		
		public var playerName:TextField;
		public var charGroup:CharacterGroup;
		
		public var friendNames:Vector.<String> = new Vector.<String>();
		public var friendBitmaps:Vector.<BitmapWrapper> = new Vector.<BitmapWrapper>();
		public var playerChatWrapper:BitmapWrapper;
		
		private var friendsBox:ProfileFriends;
		private var costumesBox:ProfileCostumes;
		private var chatsBox:ProfileChats;
		
		private var likes:uint = 12;
		private var likesBar:MovieClip;
		private var likesTxt:TextField;
		
		private var islands:uint = 34;
		private var islandsBar:MovieClip;
		private var islandsTxt:TextField;
				
		private var stickersAsset:MovieClip;
		private var stickerContainer:MovieClip;
		private var stickersJSON:Object;
		private var stickerIds:Object;
		
		private var backgroundsAsset:MovieClip;
		private var backgroundsContainer:MovieClip;
		private var backgroundsJSON:Object;
		private var backgroundsIds:Object;
		
		public var lookConverter:LookConverter;
		
		public var loginData:Object;
		private var clubhouseLogin:String;
		private var activeIsMember:Boolean = true;
		
		public function Profile()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/hub/profile/";
			shellApi.loadFile(shellApi.assetPrefix + "scenes/hub/profile/popups/stickers.swf", Command.create(stickersLoaded));
			shellApi.loadFile(shellApi.assetPrefix + "scenes/hub/profile/backgrounds.swf", Command.create(backgroundsLoaded));
			super.init(container);
		}
		
		// all assets ready
		override public function loaded():void
		{
			_interactive = super.hitContainer as MovieClip;	
			_interactive.mouseEnabled = false;
			backgroundsContainer = _interactive["backgroundContainer"];
			
			var profile:ProfileData = super.shellApi.profileManager.active;
			
			//check to see if player has registered. If not, show message and redirect.
			if(profile.pass_hash == '' && profile.login != 'default1')
			{
				var popup:ProfileMemberPopup = super.addChildGroup( new ProfileMemberPopup(super.overlayContainer, true )) as ProfileMemberPopup;
				popup.id = "profileMemberPopup";
				popup.removed.addOnce(noSavedProfile);
				//returnToPreviousScene(this);
				_interactive["profileBox"].visible = false;
				_interactive["friendsBox"].visible = false;
				_interactive["costumeBox"].visible = false;
				_interactive["chatsBox"].visible = false;
				_interactive["photoBox"].visible = false;
				
				super.groupReady();
			} 
			else 
			{
				lookConverter = new LookConverter();
				clubhouseLogin = this.shellApi.sceneManager.clubhouseLogin;
				_interactive["stickerBox"].visible = false;
				loginData = new Object();
				loginData.playerLogin = profile.login == 'default1' ? 'omino101' : profile.login;
				loginData.playerLook = lookConverter.lookDataFromPlayerLook(profile.look);
				loginData.playerName = profile.login == 'default1' ? 'test profile' : profile.avatarName;
				loginData.playerDBID = profile.login == 'default1' ? 2 : profile.dbid;
				loginData.playerHash = profile.login == 'default1' ? '9b42f486c4123f7742e5d42bc55ef493' : profile.pass_hash;
				
				if (clubhouseLogin != null)
				{	
					this.shellApi.sceneManager.clubhouseLogin = null;
					var loginArray:Array = clubhouseLogin.split("|||");
					
					var login:String = loginArray[0];
					var name:String = loginArray[1];
					var lookData:LookData = lookConverter.lookDataFromLookString(loginArray[2]);
					
					//set currProfile to clubhouse login profile
					loginData.activeLogin = login; 
					loginData.activeLook = lookData;
					loginData.activeName = name; 
				} else {
					//set currProfile to player's profile
					loginData.activeLogin = loginData.playerLogin;
					loginData.activeLook = loginData.playerLook;
					loginData.activeName = loginData.playerName;
				}
				// for tracking
				selfOrFriend = loginData.playerLogin == loginData.activeLogin ? "self" : "friend";
			
				if( true ) 
				{
					Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.ARROW;
				}
				
				// add systems for slider & scroll box
				super.addSystem(new DraggableSystem());
				super.addSystem(new SliderSystem());
				
				charGroup = new CharacterGroup();
				charGroup.setupGroup(this, _interactive);
				
				// remove special abilities
				// NOTE: seems that SpecialAbilityControlSystem is active before loaded() is called
				this.removeSystemByClass(SpecialAbilityControlSystem);
				charGroup.removeSystemByClass(SpecialAbilityControlSystem);
								
				setupProfile();
				setupBtns();
				setupLikes();
				setUpPhotoBoard();
				friendsBox = new ProfileFriends(this, _interactive);
				costumesBox = new ProfileCostumes(this, _interactive);
				//super.groupReady();
			}
		}
		
		public function setReady():void 
		{
			super.groupReady();
		}
		
		private function setupProfile():void 
		{
			_interactive.profileBox.mouseEnabled = false;
			_interactive.profileBox.mouseChildren = true;
			
			var nameFormat:TextFormat = new TextFormat("GhostKid AOE");
			var name:String;
			name = loginData.activeName;
			playerName = TextUtils.convertText( _interactive.profileBox["playerNameText"], nameFormat, capFirsts(name) );
			playerName.autoSize = TextFieldAutoSize.CENTER;
			if(playerName.textWidth > 276){
				playerName.scaleX = playerName.scaleY = 276 / playerName.textWidth;
				playerName.x = 310 - (playerName.width / 2);
			} else {
				playerName.scaleX = playerName.scaleY = 1;
				playerName.x = 185;
			}
			_interactive.profileBox.moodIcon.x = playerName.x + playerName.width;			
			
			var type:String = CharacterCreator.TYPE_DUMMY;
			if(PlatformUtils.isMobileOS)
				type = CharacterCreator.TYPE_PORTRAIT;
			
			_interactive.profileBox.profileImage.avatarContainer.removeChildren();
			var npc:Entity = charGroup.createDummy("playerModel", loginData.activeLook, "left", "", _interactive.profileBox.profileImage.avatarContainer, this, setupProfileImage,false,.35,type,new Point(10, 0));
			
			setupIslandsBar();
			setupMood();
			getStickersList();
			getWallpaperList();
		}
		
		public function checkPlayerLook():void 
		{
			var profile:ProfileData = super.shellApi.profileManager.active;
			var ld:LookData = lookConverter.lookDataFromPlayerLook(profile.look);
			var s1:String = lookConverter.getLookStringFromLookData(ld);
			var s2:String = lookConverter.getLookStringFromLookData(loginData.playerLook);
			
			if(s1 != s2)
			{
				this.shellApi.loadScene( Profile );
			}
		}
		
		private function setupIslandsBar():void 
		{
			var vars:URLVariables = new URLVariables();
			vars.login = loginData.playerLogin;
			vars.pass_hash = loginData.playerHash;
			vars.dbid = loginData.playerDBID;
			vars.scene = "Profile";
			vars.limit = 20;
			vars.last_seq = 0;
			vars.lookup_user = loginData.activeLogin;
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/quidgets/get_quidgets.php", vars, URLRequestMethod.POST, setIslandBar, myErrorFunction);
		}
		
		private function setIslandBar(event:Event):void 
		{
			var return_vars:URLVariables = new URLVariables(event.target.data);
			if(return_vars.answer == "ok")
			{
				var obj:Object = JSON.parse(return_vars.user_quidget_json);
				islands = obj.quidgets[0].total;	
				islandsBar = _interactive.profileBox.islandsBar;
				var islandsFormat:TextFormat = new TextFormat("Billy Serif");
				islandsTxt = TextUtils.convertText( islandsBar.txt, islandsFormat, islands + " Islands Completed" );
				islandsTxt.autoSize = TextFieldAutoSize.LEFT;
				islandsBar.bar.width = islandsTxt.textWidth + 40;
				for each(var a:Object in obj.quidgets){
					if(a.name == "membership"){
						//if(a.status == "notmember"){
							//_interactive["profileBox"]["profileImage"]["membership"].visible = false;
						//}
					}
				}
			}
		}
		
		private function setupMood():void 
		{
			var vars:URLVariables = new URLVariables();
			vars.login = loginData.playerLogin;
			vars.pass_hash = loginData.playerHash;
			vars.dbid = loginData.playerDBID;
			vars.lookup_user = loginData.activeLogin;
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/quidgets/get_user_mood.php", vars, URLRequestMethod.POST, setMood, myErrorFunction);
		}
		
		private function setMood(event:Event):void 
		{
			if(event.target.data != ""){
				var return_vars:URLVariables = new URLVariables(event.target.data);
				if(return_vars.answer == "ok")
				{
					_interactive.profileBox.moodIcon.mood.gotoAndStop(Number(JSON.parse(return_vars.user_mood_json)));
				} else {
					_interactive.profileBox.moodIcon.mood.gotoAndStop(10);
				}
			} else {
				_interactive.profileBox.moodIcon.mood.gotoAndStop(10);
			}
		}
		
		private function setUpPhotoBoard():void
		{
			photoBoard = addChildGroup(new PhotoBoardGroup(groupContainer,loginData.activeLogin)) as PhotoBoardGroup;
			photoBoard.ready.addOnce(addPhotosToBoard);
		}
		
		private function addPhotosToBoard(group:PhotoBoardGroup):void
		{
			//need to know ahead of time because some photos can load instantly while others take time
			var photoNames:Array = DictionaryUtil.getKeys(photoBoard.picDatas);
			photoNames.sort(PhotoBoardGroup.sortByDate);
			numPhotots = Math.min(6, photoNames.length);
			photos = [];
			if(photoNames.length > 0)
				photoBoard.recreatePhoto(photoNames[0], Command.create(photoRecreated, photoNames))
		}
		
		private function photoRecreated(photo:Sprite, photoNames:Array):void
		{
			var content:MovieClip = _interactive["photoBox"];
			
			photo.visible = false;
			content.addChild(photo);
			photos.push(photo);
			//when all photos added organize
			if(photos.length == numPhotots)
			{
				var bounds:MovieClip = content["photoContainer"];
				content.mouseChildren = true;
				var rows:int = numPhotots >= 3? 2 : 1;
				var cols:int = numPhotots == 2? 2 : Math.ceil(numPhotots/2.0);
				GridAlignment.distributeScaled(photos,bounds.getRect(content),cols,rows);
				var interaction:Interaction;
				var entity:Entity;
				for(var i:int = 0; i < photos.length; i++)
				{
					photo = photos[i];
					photo.visible = true;
					entity = EntityUtils.createSpatialEntity(this,photo);
					interaction = InteractionCreator.addToEntity(entity, [InteractionCreator.CLICK]);
					interaction.click.add(Command.create(clickPhoto, i));
					ToolTipCreator.addToEntity(entity);
				}
			}
			else
			{
				photoBoard.recreatePhoto(photoNames[photos.length],Command.create(photoRecreated, photoNames));
			}
		}
		
		private function clickPhoto(entity:Entity, index:int):void
		{
			var popup:PhotoBoardPopup = super.addChildGroup( new PhotoBoardPopup( super.overlayContainer, index)) as PhotoBoardPopup;
		}
		
		private function setupLikes(event:Event=null):void
		{
			if(event != null){
				var obj:Object = JSON.parse(event.target.data);
				if(obj.answer != "ok")
				{
					return;
				}
			}
			var vars:URLVariables = new URLVariables();
			vars.login = loginData.activeLogin;
			vars.like_login = loginData.activeLogin;
			
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/interface/PopLikes/getLikes", vars, URLRequestMethod.POST, setLikes, myErrorFunction);
		}
		
		private function setLikes(event:Event):void
		{
			var obj:Object = JSON.parse(event.target.data);
			if(obj.answer == "ok")
			{
				if(obj.likes){
					likes = obj.likes.like;
				}
				likesBar = _interactive.profileBox.likesBar;
				var likesFormat:TextFormat = new TextFormat("Billy Serif");
				likesTxt = TextUtils.convertText( likesBar.txt, likesFormat, likes + " Likes" );
				likesTxt.autoSize = TextFieldAutoSize.LEFT;
				likesBar.bar.width = likesTxt.textWidth + 40;
			}
		}
		
		private function setupBtns():void 
		{	//if viewing your own profile
			if(clubhouseLogin == null){
				MovieClip(MovieClip(_interactive)["settingsBtn"]).visible = false;
					/*
				var settingsBtn:Entity = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_interactive)["settingsBtn"]), this);
				settingsBtn.remove(Timeline);
				var settingsBtnInteraction:Interaction = settingsBtn.get(Interaction);
				
				settingsBtnInteraction.down.add(this.clickSettingsBtn);
				*/
				//make moodBtn clickable only if in your own profile
				var moodBtn:Entity = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_interactive.profileBox.moodIcon)), this);
				moodBtn.remove(Timeline);
				var moodInteraction:Interaction = moodBtn.get(Interaction);
				moodInteraction.down.add(this.clickMoodIcon);
				
				//show friend button only when on someone else's profile
				MovieClip(_interactive["friendBtn"]).visible = false;
				
			} else {
				//show settings button only when on your own profile
				MovieClip(_interactive)["settingsBtn"].visible = false;
				//friendBtn takes you back to your profile
				var friendBtn:Entity = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_interactive["friendBtn"])), this);
				friendBtn.remove(Timeline);
				var friendInteraction:Interaction = friendBtn.get(Interaction);
				friendInteraction.down.add(this.clickFriendBtn);
			}
			/*
			var photoBoardBtn:Entity = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_interactive)["photoBox"]), this);
			photoBoardBtn.remove(Timeline);
			var photoBoardInteraction:Interaction = photoBoardBtn.get(Interaction);
			photoBoardInteraction.down.add(this.clickPhotoBoardBtn);
			*/
			var likesBtn:Entity = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_interactive.profileBox.likesBar)), this);
			likesBtn.remove(Timeline);
			var likesInteraction:Interaction = likesBtn.get(Interaction);
			likesInteraction.down.add(this.clickLikesBtn);
			
			var clubhouseBtn:Entity = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_interactive.profileBox.clubhouseBar)), this);
			clubhouseBtn.remove(Timeline);
			var clubhouseInteraction:Interaction = clubhouseBtn.get(Interaction);
			clubhouseInteraction.down.add(this.clickClubhouseBtn);
			
			var blimpBtn:Entity = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_interactive.balloonBtn)), this);
			blimpBtn.remove(Timeline);
			var blimpInteraction:Interaction = blimpBtn.get(Interaction);
			blimpInteraction.down.add(this.clickBlimpBtn);
		}
		
		private function clickBlimpBtn(entity:Entity):void 
		{
			returnToPreviousScene(this);
		}
		
		private function clickFriendBtn(entity:Entity):void 
		{
			this.shellApi.loadScene( Profile );
		}
		
		private function clickMoodIcon(entity:Entity):void 
		{
			// tracking
			shellApi.track(TRACK_CLICK_MOOD_ICON, null, selfOrFriend, "Mood");
			
			var xpos:Number = _interactive.profileBox.moodIcon.x + 30;
			var popup:MoodPopup = super.addChildGroup( new MoodPopup( loginData, xpos, super.overlayContainer )) as MoodPopup;
			popup.id = "moodPopup";
			popup.reloadMood = reloadMood;
		}
		
		private function reloadMood():void 
		{
			setupMood();
		}
		
		private function clickClubhouseBtn(entity:Entity):void 
		{
			// tracking
			shellApi.track(TRACK_CLICK_CLUBHOUSE_BTN, null, selfOrFriend, "Badges");
			
			Clubhouse.loadClubhouse(shellApi, loginData.activeLogin);
		}
		
		private function clickLikesBtn(entity:Entity):void 
		{
			// tracking
			shellApi.track(TRACK_CLICK_LIKE_BTN, null, selfOrFriend, "Badges");
			
			var vars:URLVariables = new URLVariables();
			vars.login = loginData.playerLogin;
			vars.pass_hash = loginData.playerHash;
			vars.dbid = loginData.playerDBID;
			vars.like_login = loginData.activeLogin;
			vars.like_type = "like";
			
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/interface/PopLikes/like", vars, URLRequestMethod.POST, setupLikes, myErrorFunction);
		}
		
		private function displayLikes():void
		{
			likesTxt.text = likes + " Likes";
			likesBar.bar.width = likesTxt.textWidth + 40;
		}
		/*
		private function clickPhotoBoardBtn(entity:Entity):void 
		{
			// don't open popup until photoboard is ready
			if(photos.length != numPhotots)
				return;
			//var popup:PhotoBoardPopup = super.addChildGroup( new PhotoBoardPopup( super.overlayContainer )) as PhotoBoardPopup;
			//popup.id = "photoBoardPopup";
		}
		*/
		public function clickChatBtn(entity:Entity):void 
		{
			// tracking
			shellApi.track(TRACK_CLICK_CHAT_BTN, null, selfOrFriend, "Messages");
			
			var popup:ChatPopup = super.addChildGroup( new ChatPopup( loginData, super.overlayContainer )) as ChatPopup;
			popup.id = "chatPopup";
			popup.reloadChats = chatsBox.reloadChats;
		}
		
		private function clickSettingsBtn(entity:Entity):void 
		{
			// tracking
			shellApi.track(TRACK_CLICK_SETTINGS_BTN, null, selfOrFriend, "StickerWall");
			

				var popup:StickerWallPopup = super.addChildGroup( new StickerWallPopup(loginData, super.overlayContainer )) as StickerWallPopup;
				popup.id = "stickerWallPopup";
				popup.setItems = setItems;
				popup.reloadWallpaper = reloadWallpaper;

		
		}
		
		public function setItems(array:Array):void
		{
			stickerContainer = _interactive["stickerBox"]["container"];
			stickerContainer.removeChildren();
			var container:MovieClip = stickersAsset["stickerContainer"];
			for (var i:uint=0;i<array.length;i++) {
				var s:MovieClip = container[array[i][0]];
				s.x = array[i][1];
				s.y = array[i][2];
				var wrapper:BitmapWrapper = super.convertToBitmapSprite(s, null, false, 1);
				var wrap:BitmapWrapper = wrapper.duplicate();
				stickerContainer.addChild(wrap.sprite);
			}
		}
		
		private function setupProfileImage(entity:Entity):void
		{
			stillNPCLoaded(entity, 0.5);
		}
		
		public function stillNPCLoaded(entity:Entity, size:Number=0.3):void
		{
			entity.get(Spatial).scaleX = entity.get(Spatial).scaleY = size;
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
			Command.callAfterDelay(bitmapNPC, 100, entity, size);
		}
		
		private function bitmapNPC(entity:Entity, size):void 
		{
			var glowF : GlowFilter = new GlowFilter(0xFFFFFF, .9, 6, 6, 8, 1);
			if(size == 0.18){ //friend avatars
				var wrapper:BitmapWrapper = super.convertToBitmapSprite(entity.get(Display).displayObject, null, false, 0.15);
				wrapper.sprite.scaleX = wrapper.sprite.scaleY = 0.15;
				friendNames.push(entity.get(Id).id);
				friendBitmaps.push(wrapper);
				wrapper.sprite.visible = false;
				if(friendBitmaps.length - 1 == friendsBox.friendsArray.length)
				{ 
					_interactive.chatsBox.mouseEnabled = false;
					_interactive.chatsBox.mouseChildren = true;
					chatsBox = new ProfileChats(this, _interactive);
				}
			}
			if(size == 0.5){ //main player avatar
				var pwrapper:BitmapWrapper = super.convertToBitmapSprite(entity.get(Display).displayObject, null, false, 0.15);
				pwrapper.sprite.scaleX = pwrapper.sprite.scaleY = 0.15;
				playerChatWrapper = pwrapper;
				friendNames.push(loginData.activeLogin);
				friendBitmaps.push(pwrapper);
				pwrapper.sprite.visible = false;
			}
			
			var bgWrapper:BitmapWrapper = super.convertToBitmapSprite(entity.get(Display).displayObject, entity.get(Display).displayObject.parent, true, size);
			bgWrapper.sprite.scaleX = bgWrapper.sprite.scaleY = size;
			bgWrapper.sprite.filters = [glowF];
			this.removeEntity(entity);
		}
		
		public function noChats():void // no friends so need to start this here
		{
			_interactive.chatsBox.mouseEnabled = false;
			_interactive.chatsBox.mouseChildren = true;
			chatsBox = new ProfileChats(this, _interactive);
		}
		
		private function stickersLoaded(movieClip:MovieClip):void
		{
			stickersAsset = movieClip;
		}
		
		private function getStickersList():void 
		{
			var vars:URLVariables = new URLVariables();
			vars.login = loginData.playerLogin;
			vars.pass_hash = loginData.playerHash;
			vars.dbid = loginData.playerDBID;
			
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/interface/StickerWall/list", vars, URLRequestMethod.POST, setStickerList, myErrorFunction);
		}
		
		private function setStickerList(event:Event=null):void
		{
			stickersJSON = JSON.parse(event.target.data);
			stickerIds = new Object();
			for each(var sticker:Object in stickersJSON.stickers){
				stickerIds[sticker.item_id] = sticker.item_name;
			}
			var vars:URLVariables = new URLVariables();
			vars.login = loginData.playerLogin;
			vars.pass_hash = loginData.playerHash;
			vars.dbid = loginData.playerDBID;
			vars.lookup_user = loginData.activeLogin;
			
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/interface/StickerWall/get", vars, URLRequestMethod.POST, setupStickerWall, myErrorFunction);
		}
		
		private function setupStickerWall(event:Event):void
		{
			var obj:Object = JSON.parse(event.target.data);
			var array:Array = [];
			for each(var sticker:Object in obj.stickers){
				var a:Array = [];
				var name:String = stickerIds[sticker.item_id].slice(0, -8);
				a.push(name);
				a.push(sticker.x);
				a.push(sticker.y);
				array.push(a);
			}
			setItems(array);
		}
		
		private function backgroundsLoaded(movieClip:MovieClip):void 
		{
			backgroundsAsset = movieClip;
		}
		
		private function getWallpaperList():void 
		{
			var vars:URLVariables = new URLVariables();
			vars.login = loginData.playerLogin;
			vars.pass_hash = loginData.playerHash;
			vars.dbid = loginData.playerDBID;
			
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/interface/Wallpaper/list", vars, URLRequestMethod.POST, setWallpapers, myErrorFunction);
		}
		
		private function setWallpapers(event:Event=null):void 
		{
			if(event != null){
				backgroundsJSON = JSON.parse(event.target.data);
			}
			var vars:URLVariables = new URLVariables();
			vars.login = loginData.playerLogin;
			vars.pass_hash = loginData.playerHash;
			vars.dbid = loginData.playerDBID;
			vars.lookup_user = loginData.activeLogin;
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/interface/Wallpaper/get", vars, URLRequestMethod.POST, setWallpaper, myErrorFunction);
		}
		
		private function setWallpaper(event:Event):void 
		{
			var obj:Object = JSON.parse(event.target.data);
			if(obj.answer == "ok"){
				if(obj.wallpaper_id != 0){
					var name:String = "";
					for each(var wallpaper:Object in backgroundsJSON.wallpapers){
						if(wallpaper.item_id == obj.wallpaper_id) {
							name = wallpaper.item_name.slice(0, -10);
							break;
						}
					}
					if(name != ""){
						backgroundsContainer.removeChildren();
						
						var s:Sprite = new Sprite();
						var bgWrapper:BitmapWrapper = super.convertToBitmapSprite(backgroundsAsset[name], s, false);	
						backgroundsContainer.addChild(s);
					}
				}
			}
		}
		
		public function reloadWallpaper():void 
		{
			setWallpapers();
		}
		
		//player has not registered yet
		private function noSavedProfile(...args):void 
		{
			returnToPreviousScene(this);
		}
		
		// return to previous scene on click
		private function returnToPreviousScene(group:Group):void
		{
			var sceneManager:SceneManager = shellApi.sceneManager;
			var destScene:String = sceneManager.previousScene;
			var destX:Number = sceneManager.previousSceneX;
			var destY:Number = sceneManager.previousSceneY;
			
			if (destScene.indexOf('.') > -1) {
				shellApi.loadScene(ClassUtils.getClassByName(destScene), destX, destY, sceneManager.previousSceneDirection);
			}
			else
			{
				shellApi.loadScene(Town);
			}
		}
		
		private function capFirsts(txt:String):String
		{
			return txt.replace(/\b./g,function(...m):String{return m[0].toUpperCase()});
		}
		
		private function myErrorFunction(event:Event):void
		{
			
		}
		
		override public function destroy():void
		{
			
			super.destroy();
		}
	}
}
