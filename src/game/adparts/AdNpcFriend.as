package game.adparts
{
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.SharedObject;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import ash.core.Entity;
	
	import engine.ShellApi;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterProximity;
	import game.components.input.Input;
	import game.components.motion.TargetEntity;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.ads.AdData;
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.AdvertisingConstants;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.scene.SceneType;
	import game.managers.SceneManager;
	import game.managers.ads.AdManager;
	import game.proxy.Connection;
	import game.proxy.IDataStore;
	import game.scene.template.CharacterDialogGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.SceneUIGroup;
	import game.scene.template.ui.CardGroup;
	import game.systems.motion.ThresholdSystem;
	import game.ui.costumizer.CostumizerPop;
	import game.ui.showItem.ShowItem;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.utils.AdUtils;
	
	/**
	 * Class for handling NPC friends 
	 * @author VHOCKRI
	 */
	public class AdNpcFriend
	{
		public function AdNpcFriend()
		{
		}
		
		/**
		 * Initialize class 
		 * @param scene
		 * @param shellApi
		 */
		public function init(scene:PlatformerGameScene, shellApi:ShellApi):void
		{
			_parentScene = scene;
			_shellApi = shellApi;
		}
		
		/**
		 * Setup NPC friend (called by AdSceneGroup)
		 * @param isSupported Boolean for whether NPC friend is supported for this platform (Mobile is no)
		 * @param npcType AdType for NPC friend (can be browser or mobile)
		 */
		public function setup(isSupported:Boolean, npcType:String):void
		{
			// remember type
			_npcCampaignType = npcType;
			_npcFriend = null;
			
			// if supported for this platform
			if (isSupported)
			{
				// look for npc friend campaign data on main street
				_adData = _shellApi.adManager.getAdData(_npcCampaignType, false, true);
				if (_adData == null)
					trace("NPC friend not found in CMS");
				else
					trace("NPC friend found in CMS: " + _adData.campaign_name);
			}
			else
			{
				// if not supported on this platform
				trace("NPC friend not supported on this platform");
			}
			
			// check for NPC friend in front of ad building (not bitmap; bitmaps not supported)
			// NPC friend in front of ad buildings should be named "npc_friend_ad"
			_adBuildingNPC = _parentScene.getEntityById("npc_friend_ad");
			// if found ad building NPC
			if (_adBuildingNPC)
			{
				// if no data then delete ad building NPC
				if (_adData == null)
					_parentScene.removeEntity(_adBuildingNPC);
				
				// remove standard NPC friend from main street (we don't want two NPC friends on main street)
				var msEntity:Entity = _parentScene.getEntityById("npc_friend");
				if (msEntity)
					_parentScene.removeEntity(msEntity);
			}
			else
			{
				// else look for NPC friend on main street
				// main street NPC friend
				_mainStreetNPC = _parentScene.getEntityById("npc_friend");
				if (_mainStreetNPC)
				{
					// if no data then delete
					if (_adData == null)
						_parentScene.removeEntity(_mainStreetNPC);
				}
			}
			
			// bitmap NPC friend (haven't added case for bitmap NPC in front of ad building)
			_bitmapNPC = _parentScene.getEntityById("npc_friend_bitmap");
			if (_bitmapNPC != null)
			{
				// if no data then delete
				if (_adData == null)
					_parentScene.removeEntity(_bitmapNPC);
			}
			
			// if data, then load xml
			if (_adData)
			{
				// pulls from xpop in FlashBuilder
				// get setup data from file2
				var path:String = "https://" + (_shellApi.siteProxy as IDataStore).fileHost + "/framework/npcfriends/xml/" + _adData.campaign_file2;
				_shellApi.loadFile(path, gotNPCXML);
			}
		}
		
		/**
		 * When received xml for npc friend 
		 * @param xml
		 */
		private function gotNPCXML(xml:XML):void
		{
			// if no xml then return
			if (xml == null)
				return;
			
			// if main street scene but don't show on main street according to xml, then delete main street npc friends
			if ((SceneManager(_shellApi.getManager(SceneManager)).currentScene.sceneData.sceneType == SceneType.MAINSTREET) && (xml.show_on_main_street == "false"))
			{
				_parentScene.removeEntity(_adBuildingNPC);
				_parentScene.removeEntity(_mainStreetNPC);
				_parentScene.removeEntity(_bitmapNPC);
			}
			else
			{
				// if not supressing NPCs
				// get campaign name
				_NPCFriendCampaign = _adData.campaign_name;
				// get user name
				_NPCFriendUserName = xml.user_name;
				// button offset for Poptropican NPC for lowest button
				var buttonOffsetY:Number = 80;
				
				// if bitmapped NPC
				if (xml.bitmap == "true")
				{
					trace("NPC friend: bitmapped" + _NPCFriendUserName);
					// set friend to bitmapped NPC
					_npcFriend = _bitmapNPC;
					
					// remove standard NPC and ad building NPC
					_parentScene.removeEntity(_mainStreetNPC);
					_parentScene.removeEntity(_adBuildingNPC);
					
					// load external NPC asset
					_shellApi.loadFile(_shellApi.assetPrefix + AdvertisingConstants.AD_PATH_KEYWORD + "/" + _NPCFriendCampaign + "/" + xml.bitmap_file, loadedBitmapNPC);
					// offset for friend button
					buttonOffsetY = Number(xml.talk_height) + 13; // allow for half height (13) of friend button
				}
				// if poptropican npc and npc entity exists
				else if (_mainStreetNPC || _adBuildingNPC)
				{
					trace("NPC friend: poptropican: " + _NPCFriendUserName);
					// point NPC friend to valid Poptropican NPC
					if (_mainStreetNPC)
						_npcFriend = _mainStreetNPC;
					else
						_npcFriend = _adBuildingNPC;
					
					// remove bitmapped NPC
					_parentScene.removeEntity(_bitmapNPC);
					
					// set walk range - not supported (if we add this then the friend button needs to move when they walk)
					// best if they don't walk for now
					//var left:Number = Number(look[0]);
					//var right:Number = Number(look[1]);
					//var up:Number = Number(look[2]);
					//var down:Number = Number(look[3]);
					
					// create look string
					// 9-eyesF, 10-mouthF, 11-marksF, 12-facialF, 13-hairF, 14-shirtF, 15-pantsF, 16-packF, 17-itemF, 18-overshirtF, 19-overpantsF
					// note: mouth must be from 1-19, eyes from 1-28 or be "string"
					var lookString:String = xml.gender + "," + xml.skincolor + "," + xml.haircolor + ",x,x," + xml.eyestate + "," + xml.marks + "," + xml.pants + ",x,";
					lookString += (xml.shirt + "," + xml.hair + "," + xml.mouth + "," + xml.item + "," + xml.pack + "," + xml.facial + "," + xml.overshirt + "," + xml.overpants);
					
					// apply look to NPC
					var lookConv:LookConverter = new LookConverter();
					// get convert look string into look object, then apply
					var lookData:LookData = lookConv.lookDataFromLookString(lookString);
					SkinUtils.applyLook( _npcFriend, lookData, true, doneLook );
					
					// force avatar to face NPC when interact
					_npcFriend.get(Dialog).faceSpeaker = false;
				}
				else if (_bitmapNPC)
				{
					// if bitmapped NPC but bitmap is not specified then remove entity
					_parentScene.removeEntity(_bitmapNPC);
				}
			}
			
			// if NPC friend
			if (_npcFriend)
			{
				// hide until look is applied
				_npcFriend.get(Display).visible = false;
				
				// extend button offset to topmost button based on number of buttons
				if (String(xml.numButtons) != "")
					_numButtons = DataUtils.getUint(xml.numButtons);
				buttonOffsetY += (_numButtons * BUTTON_SPACING);
				
				// get x and y positions based on NPC and offsets
				var npcSpatial:Spatial = _npcFriend.get(Spatial);
				_buttonX = npcSpatial.x;
				_buttonY = npcSpatial.y - buttonOffsetY;
				
				// track impression with display name
				AdManager(_shellApi.adManager).track(_NPCFriendCampaign, AdTrackingConstants.TRACKING_IMPRESSION, _npcCampaignType, xml.display_name);
				
				// load buttons
				if (String(xml.chatBtnPos) != "")
					_chatBtnPos = DataUtils.getUint(xml.chatBtnPos)
				if (_chatBtnPos != 0)
					_shellApi.loadFile(_shellApi.assetPrefix + "ui/general/chatBtn.swf", loadedChatButton);
				
				if (String(xml.costumizeBtnPos) != "")
					_costumizeBtnPos = DataUtils.getUint(xml.costumizeBtnPos)
				if (_costumizeBtnPos != 0)
					_shellApi.loadFile(_shellApi.assetPrefix + "ui/general/costumizeBtn.swf", loadedCostumizeButton);
				
				if (String(xml.friendBtnPos) != "")
					_friendBtnPos = DataUtils.getUint(xml.friendBtnPos)
				if (_friendBtnPos != 0)
					_shellApi.loadFile(_shellApi.assetPrefix + "ui/general/friendBtn.swf", loadedFriendButton);
				
				if (String(xml.prizeBtnPos) != "")
					_prizeBtnPos = DataUtils.getUint(xml.prizeBtnPos)
				if (_prizeBtnPos != 0)
					_shellApi.loadFile(_shellApi.assetPrefix + "ui/general/prizeBtn.swf", loadedPrizeButton);
				
				// add scene click listener to hide friend buttons
				_shellApi.inputEntity.get(Input).inputDown.add(hideButtons);
				
				// listener for clicking on NPC friend
				_npcFriend.get(Interaction).click.add(npcFriendClicked);
				
				// get dialog from xml for main street only (ad buildings use dialog from xml)
				if (_npcFriend.get(Id).id != "npc_friend_ad")
				{
					var characterDialogGroup:CharacterDialogGroup = _parentScene.getGroupById(CharacterDialogGroup.GROUP_ID) as CharacterDialogGroup;
					characterDialogGroup.addAllDialog(XML(xml.dialog_main_street_as3));
				}
				
				// load optional logo to appear below NPC friend
				if (xml.logo == "true")
				{
					var npcName:String = _NPCFriendUserName.substr(_NPCFriendUserName.indexOf(":") + 1);
					_shellApi.loadFile(_shellApi.assetPrefix + AdvertisingConstants.AD_PATH_KEYWORD + "/" + _NPCFriendCampaign + "/" + npcName + "_logo.swf", loadedNPCLogo);
				}
				
				// get cards based on gender
				switch(_shellApi.profileManager.active.gender)
				{
					case SkinUtils.GENDER_MALE:
					case null:
						if (String(xml.cards_male) != "")
							_cards = xml.cards_male.split(",");
						break;
					case SkinUtils.GENDER_FEMALE:
						if (String(xml.cards_female) != "")
							_cards = xml.cards_female.split(",");
						break;
				}
				checkCards();
				
				// if proximity dialog and has cards
				if ((_hasCards) && (String(xml.proximity) != ""))
				{
					var distance:int = DataUtils.getUint(xml.proximity);
					var charProximity:CharacterProximity = new CharacterProximity();
					charProximity.proximity = distance;
					_npcFriend.add( charProximity );

					// setup NPC for proximity trigger of dialog				
					// setup threshold for entering
					var threshold:Threshold = new Threshold( "x", "<>", _npcFriend, distance );
					threshold.entered.add( Command.create(triggerNpcProximity, _npcFriend) );
					_shellApi.player.add( threshold );
					
					// add threshold system is not added
					if (!_parentScene.getSystem(ThresholdSystem))
					{
						_parentScene.addSystem(new ThresholdSystem());
					}
				}
			}
		}
		
		/**
		 * Trigger NPC dialog when when avatar walks by
		 * @param npcEntity
		 */
		private function triggerNpcProximity(npcEntity:Entity):void
		{
			// if cards to award
			if (_hasCards)
			{
				// check if target entity
				var targetEntity:TargetEntity = _shellApi.player.get(TargetEntity);
				// if no target entity or didn't click on NPC then can trigger
				if ((targetEntity == null) || (targetEntity.active))
				{
					CharUtils.sayDialog(npcEntity,"proximity");
				}
			}
		}

		/**
		 * When done applying look to NPC friend
		 * @param entity
		 */
		private function doneLook(entity:Entity):void
		{
			// make NPC visible
			_npcFriend.get(Display).visible = true;
		}
		
		/**
		 * When logo is loaded 
		 * @param asset logo movie clip
		 */
		private function loadedNPCLogo(asset:MovieClip):void
		{
			// get NPC clip holder
			var npc:MovieClip = MovieClip(_npcFriend.get(Display).displayObject);
			// add logo as child of NPC holder
			var clip:MovieClip = MovieClip(npc.addChild(asset));
			// set the logo to be actual scale (invert NPC scale)
			clip.scaleX = clip.scaleY = 1/npc.scaleY;
			// set vertical position
			clip.y = 115;
		}
		
		/**
		 * When bitmapped NPC is loaded 
		 * @param asset Bitmapped NPC movie clip
		 */
		private function loadedBitmapNPC(asset:MovieClip):void
		{
			// get NPC clip holder
			var npc:MovieClip = MovieClip(_npcFriend.get(Display).displayObject);
			// add bitmapped NPC as child of NPC holder
			npc.addChild(asset);
			
			// convert npc embedded clip to animating timeline
			var npcClip:MovieClip = MovieClip(asset).npc;
			// if "npc" embedded clip exists and more than one frame
			if ((npcClip) && (npcClip.totalFrames != 1))
			{
				// convert to timeline (for breathing animation)
				TimelineUtils.convertClip( npcClip, _parentScene, _npcFriend );
			}
			
			// set scene interaction offset
			_npcFriend.get(SceneInteraction).offsetX = asset.width/2 + 30;	// set offset to half width plus 30
			
			// make NPC visible
			_npcFriend.get(Display).visible = true;
		}
		
		/**
		 * When click on NPC friend, then show buttons 
		 * @param clickedEntity
		 */
		private function npcFriendClicked(clickedEntity:Entity):void
		{
			// track click with user name in form "npc:name"
			AdManager(_shellApi.adManager).track(_NPCFriendCampaign, AdTrackingConstants.TRACKING_ENGAGED_NPC_FRIEND, _NPCFriendUserName);
			
			// vertical starting points for buttons
			var startY:int = 40;
			
			// setup chat button
			if (_chatButton)
				initButton(_chatButton);
			
			// setup costumize button
			if (_costumizeButton)
				initButton(_costumizeButton);
			
			if (_friendButton)
			{
				// setup friend button (set test to say FRIEND because we change the text when clicked)
				_friendButton.get(Display).displayObject.tLabel.text = "FRIEND";
				initButton(_friendButton);
			}
			
			// setup prize button if cards
			if ((_prizeButton) && (_hasCards))
			{
				initButton(_prizeButton);
			}
		}
		
		/**
		 * Initialize friend button to prepare it to animate in 
		 * @param button
		 */
		private function initButton(button:Entity):void
		{
			button.get(Spatial).y = 40;
			button.get(Spatial).scaleX = button.get(Spatial).scaleY = 0;
			button.get(Tween).to(button.get(Spatial), 0.3, { y:0, scaleY:1, scaleX:1 });
			button.get(Display).visible = true;
		}
		
		/**
		 * Hide buttons when click on scene 
		 * @param entity
		 */
		private function hideButtons(entity:Object = null):void
		{
			if (_chatButton)
				_chatButton.get(Display).visible = false;
			if (_costumizeButton)
				_costumizeButton.get(Display).visible = false;
			if (_friendButton)
				_friendButton.get(Display).visible = false;
			if (_prizeButton)
				_prizeButton.get(Display).visible = false;
		}
		
		/**
		 * Create button entity 
		 * @param clip button clip
		 * @param id button ID
		 * @param handler function when clicked
		 * @return button entity
		 */
		private function createButton(clip:DisplayObjectContainer, id:String, handler:Function):Entity
		{
			// force clip to be invisble
			clip.visible = false;
			// create button entity
			var button:Entity = ButtonCreator.createButtonEntity(clip, _parentScene, handler);
			// make invisible and non-static
			button.get(Display).visible = false;
			button.get(Display).isStatic = false;
			// add tween for animation
			button.add(new Tween());
			// add ID
			button.add(new Id(id));
			return button;
		}
		
		// Prize button stuff ==================================================================================
		
		/**
		 * Check if any cards have been awarded already
		 * This needs to happen when scene loaded or else the events get cleared
		 */
		private function checkCards():void
		{
			if (_cards + null)
			{
				// for each card
				for (var i:int = _cards.length-1; i != -1; i--)
				{
					// get card ID
					var cardID:String = _cards[i];
					// remove initial space, if any
					if (cardID.substr(0,1) == " ")
						cardID = cardID.substr(1);
					
					// if has card, then trigger event and remove from array
					if (_shellApi.checkHasItem(cardID, CardGroup.CUSTOM))
					{
						trace("NPCFriend: has card " + cardID);
						_shellApi.triggerEvent(CARD_PREFIX + cardID);
						_cards.splice(i,1);
					}
				}
				// if has cards, then set boolean
				if (_cards.length != 0)
				{
					_hasCards = true;
				}
			}
		}
		
		/**
		 * When prize button loaded 
		 * @param asset prize button movieClip
		 */
		private function loadedPrizeButton(asset:MovieClip):void
		{
			// add button to scene
			var button:MovieClip = MovieClip(_parentScene.hitContainer.addChild(asset));
			
			// set position
			button.x = _buttonX;
			button.y = _buttonY + _prizeBtnPos * BUTTON_SPACING;
			
			// create button
			_prizeButton = createButton(button.content, "prizeButton", clickPrizeButton);
		}
		
		/**
		 * Click npc prize button
		 * @param entity
		 */
		private function clickPrizeButton(button:Entity):void
		{			
			// hide buttons
			hideButtons();
			
			// if cards to award
			if ((_cards) && (_cards.length != 0))
			{
				trace("NPCFriend: awarding cards: " + _cards);
				// set card count
				_cardCount = _cards.length;
				// lock input
				SceneUtil.lockInput(_parentScene, true);
				
				// start awarding cards
				awardCards();
			}
		}
		
		/**
		 * Award cards (calls itself until done)
		 * @param e
		 */
		private function awardCards(e:Event = null):void
		{
			// do while there are cards
			if (_cards.length != 0)
			{
				// get card ID
				var cardID:String = _cards.shift();
				// remove initial space, if any
				if (cardID.substr(0,1) == " ")
					cardID = cardID.substr(1);
				
				// display card
				trace("NPCFriend: awarding card " + cardID);
				_shellApi.getItem(cardID, CardGroup.CUSTOM, true);
				_shellApi.triggerEvent(CARD_PREFIX + cardID);
				AdManager(_shellApi.adManager).track(_NPCFriendCampaign, AdTrackingConstants.TRACKING_OBJECT_COLLECTED, "Card", cardID);
				
				// setup timer for next card
				var timedEvent:TimedEvent = new TimedEvent(0.25, 1, awardCards);
				SceneUtil.addTimedEvent(_parentScene, timedEvent);
				
				// when card animation done
				ShowItem(_parentScene.getGroupById("showItemGroup")).transitionComplete.addOnce(gotCard);
			}
		}
		
		/**
		 * When card is awarded (when animation is done)
		 */
		private function gotCard():void
		{
			// decrement counter
			_cardCount--;
			
			// after last card awarded then unlock input
			if (_cardCount == 0)
			{
				SceneUtil.lockInput(_parentScene, false);
				// set to no more cards
				_hasCards = false;
			}
		}

		// Friend button stuff ==================================================================================

		/**
		 * When friend button loaded 
		 * @param asset friend button movieClip
		 */
		private function loadedFriendButton(asset:MovieClip):void
		{
			// add button to scene
			var button:MovieClip = MovieClip(_parentScene.hitContainer.addChild(asset));
			
			// set position
			button.x = _buttonX;
			button.y = _buttonY + _friendBtnPos * BUTTON_SPACING
			
			// create button
			_friendButton = createButton(button.content, "friendButton", clickFriendButton);
		}
		
		/**
		 * Click Friend button 
		 * @param button
		 */
		private function clickFriendButton(button:Entity):void
		{
			// if guest, then show message that yhou can't friend if game is not saved
			if (_shellApi.profileManager.active.isGuest)
			{
				var sceneUIGroup:SceneUIGroup = _parentScene.groupManager.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup;
				sceneUIGroup.askForConfirmation(SceneUIGroup.CANT_FRIEND_IF_NOT_SAVED, sceneUIGroup.removeConfirm, sceneUIGroup.removeConfirm);
				return;
			}
			
			// change text on button
			_friendButton.get(Display).displayObject.tLabel.text = "ADDING...";
			
			// track click with user name in form "npc:name"
			_shellApi.adManager.track(_NPCFriendCampaign, AdTrackingConstants.TRACKING_FRIEND_CLICKED, _NPCFriendUserName);

			// send message to server
			var vars:URLVariables = new URLVariables();
			// if browser or true mobile
			if ((PlatformUtils.inBrowser) || (AppConfig.mobile))
			{
				// set params to send to server
				vars.login = _shellApi.profileManager.active.login;
				vars.pass_hash = _shellApi.profileManager.active.pass_hash;
				vars.dbid = _shellApi.profileManager.active.dbid;
				vars.logged_in = 1;
			}
			else
			{
				// otherwise use testing credentials
				// use testing user on xpop
				vars.login = "testing";
				vars.pass_hash = "a12d01d1f7dde753302f3a052174203b";
				vars.dbid = 1;
				vars.logged_in = 0;
			}
			// add other params
			vars.favorite = 2;
			vars.friend_login = _NPCFriendUserName;
			vars.method = 0;
			
			// make php call to server
			var connection:Connection = new Connection();
			connection.connect(_shellApi.siteProxy.secureHost + "/friends/add_friend.php", vars, URLRequestMethod.POST, addFriendCallback, addFriendError);
		}
		
		// Friending code ================================================================================

		/**
		 * When friending callback is received from server 
		 * @param e
		 */
		private function addFriendCallback(e:Event):void
		{
			// hide all buttons
			hideButtons();
			
			// parse data
			var return_vars:URLVariables = new URLVariables(e.target.data);
			// check answer
			switch (return_vars.answer)
			{
				case "ok": // if successful
					// send tracking call
					_shellApi.adManager.track(_NPCFriendCampaign, AdTrackingConstants.TRACKING_ADD_FRIEND, _NPCFriendUserName);
					
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
					var sceneUIGroup:SceneUIGroup = _parentScene.groupManager.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup;
					sceneUIGroup.askForConfirmation(SceneUIGroup.ALREADY_FRIENDS, sceneUIGroup.removeConfirm, sceneUIGroup.removeConfirm);
					break;
				
				default: // if errors
					// possible errors: "no-such-user", "no-such-friend-login"
					// no-such-friend-login means that the NPC friend has not been setup on the server (such as xpop)
					// NPC friends on a server have a username in the form "npc:name" and password "npcfriend"
					trace("NPC Friend: AddFriendCallback Error: " + return_vars.answer);
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
				
		// Costumize button stuff ==================================================================================
		
		// loaded costumize button
		private function loadedCostumizeButton(asset:MovieClip):void
		{
			// add button to scene
			var button:MovieClip = MovieClip(_parentScene.hitContainer.addChild(asset));
			
			// set location
			button.x = _buttonX;
			button.y = _buttonY + _costumizeBtnPos * BUTTON_SPACING;
			
			// create button
			_costumizeButton = createButton(button.content, "costumizeButton", clickCostumizeButton);
		}
		
		/**
		 * Click npc costumize button
		 * @param entity
		 */
		private function clickCostumizeButton(button:Entity):void
		{
			// track click with user name in form "npc:name"
			_shellApi.adManager.track(_NPCFriendCampaign, AdTrackingConstants.TRACKING_COSTUMIZED_CLICKED, _NPCFriendUserName);

			// hide buttons
			hideButtons();

			// load costumizer
			var look:LookData = SkinUtils.getLook( _npcFriend, true );
			var costumizer:CostumizerPop = new CostumizerPop(_parentScene.overlayContainer, look);
			_parentScene.addChildGroup(costumizer);
		}

		// Chat button stuff ==================================================================================
		
		// loaded chat button
		private function loadedChatButton(asset:MovieClip):void
		{
			// add button to scene
			var button:MovieClip = MovieClip(_parentScene.hitContainer.addChild(asset));
			
			// set location
			button.x = _buttonX;
			button.y = _buttonY + _chatBtnPos * BUTTON_SPACING;
			
			// create button
			_chatButton = createButton(button.content, "chatButton", clickChatButton);
		}
		
		/**
		 * Click npc chat button
		 * @param entity
		 */
		private function clickChatButton(button:Entity):void
		{
			// track click with user name in form "npc:name"
			_shellApi.adManager.track(_NPCFriendCampaign, AdTrackingConstants.TRACKING_CHAT_CLICKED, _NPCFriendUserName);
			
			// hide buttons
			hideButtons();
			
			// say default dialog (can be conversation or statement)
			CharUtils.sayDialog(_npcFriend,"default");
		}

		private const CARD_PREFIX:String = "hasAdItem_";
		private const BUTTON_SPACING:int = 30;
		
		private var _parentScene:PlatformerGameScene;
		private var _shellApi:ShellApi;
		private var _adData:AdData;
		private var _NPCFriendCampaign:String;
		private var _NPCFriendUserName:String;
		private var _npcCampaignType:String;
		private var _npcFriend:Entity;
		private var _adBuildingNPC:Entity;
		private var _mainStreetNPC:Entity;
		private var _bitmapNPC:Entity;
		
		// buttons
		private var _numButtons:uint = 3;
		private var _buttonX:Number;
		private var _buttonY:Number;
		private var _chatButton:Entity;
		private var _chatBtnPos:uint = 1;
		private var _costumizeButton:Entity;
		private var _costumizeBtnPos:uint = 2;
		private var _friendButton:Entity;
		private var _friendBtnPos:uint = 0;
		private var _prizeButton:Entity;
		private var _prizeBtnPos:uint = 3;
		
		// prize cards
		private var _cards:Array;
		private var _cardCount:int;
		private var _hasCards:Boolean = false;
	}
}

