package game.ui.profile
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	
	import game.components.entity.character.part.eye.Eyes;
	import game.components.motion.Draggable;
	import game.components.timeline.Timeline;
	import game.components.ui.GridControlScrollable;
	import game.components.ui.Ratio;
	import game.components.ui.Slider;
	import game.creators.entity.character.CharacterCreator;
	import game.creators.ui.GridScrollableCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.character.LookData;
	import game.data.display.BitmapWrapper;
	import game.data.ui.TransitionData;
	import game.scene.template.CharacterGroup;
	import game.scene.template.SceneUIGroup;
	import game.systems.entity.EyeSystem;
	import game.systems.motion.DraggableSystem;
	import game.systems.ui.ScrollBoxSystem;
	import game.systems.ui.SliderSystem;
	import game.ui.costumizer.Costumizer;
	import game.ui.popup.Popup;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.TextUtils;
	import game.util.Utils;
	
	
	public class ProfilePopup extends Popup
	{	
		public var playerName:TextField;
		
		private var npcPosition:MovieClip;
		private var traderLook:LookData;
		private var npc:Entity;
		private var charGroup:CharacterGroup;
		
		private var friendsSlider:Entity;
		private var friendsBar:Entity;
		private var friendsRatio:Ratio;
		private var friendsInventory:MovieClip;
		private var friendsBgWrapper:BitmapWrapper;
		private var friendsInventoryBounds:Rectangle;
		private var friendsGridCreator:GridScrollableCreator;
		private var friendsGrid:Entity;
		private var friendsItems:Array;
		private var noFriendsItems:Boolean = false;
		private var friendsItemsLoaded:uint;
		private var friendsNames:Array;
		
		private var chatsSlider:Entity;
		private var chatsBar:Entity;
		private var chatsRatio:Ratio;
		private var chatsInventory:MovieClip;
		private var chatsBgWrapper:BitmapWrapper;
		private var chatsInventoryBounds:Rectangle;
		private var chatsGridCreator:GridScrollableCreator;
		private var chatsGrid:Entity;
		private var chatsItems:Array;
		private var noChatsItems:Boolean = false;
		private var chatsItemsLoaded:uint;
		
		private var costumeSlider:Entity;
		private var costumeBar:Entity;
		private var costumeRatio:Ratio;
		private var costumeInventory:MovieClip;
		private var costumeBgWrapper:BitmapWrapper;
		private var costumeInventoryBounds:Rectangle;
		private var costumeGridCreator:GridScrollableCreator;
		private var costumeGrid:Entity;
		private var costumeItems:Array;
		private var noCostumeItems:Boolean = false;
		private var costumeItemsLoaded:uint;
		
		private var _gridControl:GridControlScrollable;
		private var content:MovieClip;
		
		private const CONTAINER:String = "container";
		
		private const ALL_ITEMS:Vector.<String> = new <String>["btn1", "btn2", "btn3", "btn4", "btn5", "btn6", "btn7", "btn8", "btn9"];
		private const FRIENDS:Vector.<String> = new <String>["Poper98g", "bIGpopperNYC35", "lilpop9854b", "superpop45", "wowsers77", "poplater54323", "winwinwin", "78fundom", "buttons77"];
		private const CHATS:Vector.<String> = new <String>["Hey How Are You?", "Love your Outfit!", "See You Later", "Hello", "Fun Party", "What Island are you playing?", "I can't Wait", "Bye", "Have Fun"];

		private const ALL_COSTUME_ITEMS:Vector.<String> = new <String>["test1", "test2", "test3", "test4", "test5", "test6", "test7", "test8", "test9"];
		
		private const LOOKS:Array = [
			["female", 0xd2aa72, 0x0, "casual", "snootygirl", "19", "an_thief1", "an_thief1", "an_thief2", "an_thief2", "an_thief2", "an_thief1", "", "", "", ""],
			["male", 0xd2aa72, 0x999999, "squint", "an_brokemerch", "astroking", "", "an2_vizier", "an2_vizier", "an2_vizier", "an2_vizier", "", "", "", "", ""],
			["female", 0xE6BC7D, 0x0, "squint", "athena", "athena", "", "athena", "athena", "athena", "athena", "", "athena", "", "", ""],
			["male", 0xd2aa72, 0x0, "casual", "skullmainfarmer2", "1", "an_thief1", "an_thief1", "an_thief1", "an_thief1", "an_thief1", "an_thief1", "an_thief1", "an_thief1", "", ""],
			["male", 0xdcba71, 0x0, EyeSystem.SQUINT, "an_genie3", "78", null, "an_genie3", "an_genie3", "an_genie3", "an_genie3", "", "empty", "", "", "empty"],
			["female", 0x6bdbb6, 0x1b362d, EyeSystem.SQUINT, "an_genie2", "15", "an2_master2", "an_genie2", "an_genie2", "an_genie2", "an_princess", "", "empty", "", "", ""],
			["male", 0xd2aa72, 0x0, "casual", "ce_ranger", "1", "an_thief1", "an_thief2", "an_thief2", "an_thief2", "an_thief2", "", "", "", "", ""]
		];
		
		public function ProfilePopup(container:DisplayObjectContainer=null)
		{
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
			super.groupPrefix = "ui/profile/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["profilePopup.swf"]);
		}
		
		// all assets ready
		override public function loaded():void
		{		
			super.screen = super.getAsset("profilePopup.swf", true) as MovieClip;
			// this loads the standard close button
			super.loadCloseButton();
			super.loaded();
			playerName = screen.content["playerNameText"];
			playerName.text = capFirsts(this.shellApi.profileManager.active.avatarName);
			//playerName.scaleX = .5;
			
			// add systems for slider & scroll box
			this.addSystem(new DraggableSystem());
			this.addSystem(new SliderSystem());
			this.addSystem(new ScrollBoxSystem());
			
			content = screen.content;
			
			charGroup = new CharacterGroup();
			charGroup.setupGroup(this, content);
			
			var type:String = CharacterCreator.TYPE_DUMMY;
			if(PlatformUtils.isMobileOS)
				type = CharacterCreator.TYPE_PORTRAIT;
			
			// creates dummy avatar, if look=null returns player look
			var lookData:LookData = new LookData();
			lookData.applyLook( "male", 0xd2aa72, 0x999999, "squint", "an_brokemerch", "astroking", "", "an2_vizier", "an2_vizier", "an2_vizier", "an2_vizier", "", "", "" );
			var npc:Entity = charGroup.createDummy("trader", lookData, "left", "", content.profileImage.avatarContainer, this, stillNPCLoaded,false,.35,type,new Point(10, 0));
			
			setUpFriendsBox();
			setUpChatsBox();
			setUpCostumeBox();

			setupSlider(content.friendsSlider, friendsSlider, friendsBar, new Rectangle(-56, -5, 112, 5), friendsRatio);
			setupSlider(content.chatsSlider, chatsSlider, chatsBar, new Rectangle(-56, -5, 112, 5), chatsRatio);
			setupSlider(content.costumeSlider, costumeSlider, costumeBar, new Rectangle(-56, -5, 112, 5), costumeRatio);
			
			setupBtns();
		}
		
		private function setupBtns():void 
		{
			var bgWrapper:BitmapWrapper = super.convertToBitmapSprite(content.settingsBtn, content, false);
			
			var entity:Entity = EntityUtils.createMovingEntity( this, bgWrapper.sprite, content );
			var interaction:Interaction = InteractionCreator.addToEntity( entity, ["click"], bgWrapper.sprite ); 
			interaction.click.add(clickSettingsBtn);
			ToolTipCreator.addUIRollover(entity);
			entity.add( new Id("settingsBtn") );
			bgWrapper.sprite.visible = false;
		}
		
		private function clickSettingsBtn():void 
		{
			
		}
		
		private function stillNPCLoaded(entity:Entity):void
		{
			entity.get(Spatial).scaleX = entity.get(Spatial).scaleY = .5;
			entity.get(Timeline).paused = true;
			var eyeEntity:Entity = CharUtils.getPart( entity, CharUtils.EYES_PART );
			if( eyeEntity != null )
			{
				var eyes:Eyes = eyeEntity.get(Eyes);
				if( eyes != null )
				{
					eyes.locked = true;
				}
			}
		}
		//////////////////////////////////////////////////////////////////////////////////////////////
		//////////////////////////////////////////// FRIENDS /////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////////
		
		private function setUpFriendsBox():void
		{	
			friendsInventory = content.friendsInventory;
			//var friendNameText:TextField = content.friendsInventory["friendNameText"];
			//friendNameText.text = "HEy";
			friendsBgWrapper = super.convertToBitmapSprite(friendsInventory.itemUIBackground,friendsInventory.itemUIBackground.parent, false);
			
			friendsGridCreator = new GridScrollableCreator();
			friendsItemsLoaded = 0;
			friendsItems = [];
			
			for (var j:int = 0; j < FRIENDS.length; j++) 
			{
				friendsItems.push(FRIENDS[j]);
			}
			
			if(friendsItems.length == 0)
				noFriendsItems = true;
			
			friendsInventory.removeChild(friendsInventory.itemUIBackground);
			var ref:MovieClip = content.friendsRef;
			
			friendsInventoryBounds = ref.getBounds(friendsInventory);
			friendsInventoryBounds.x = friendsInventoryBounds.y = 0;
			friendsInventory.mask = ref;
			
			friendsGrid = friendsGridCreator.create( friendsInventoryBounds, friendsBgWrapper.sprite.getBounds(friendsBgWrapper.sprite), 1, 0, this, 5, false, null, 0, "friends_grid");
			friendsRatio = friendsGrid.get( Ratio );
			GridControlScrollable(friendsGrid.get(GridControlScrollable)).createSlots( friendsItems.length, 0, 1);
			for (var i:int = 0; i < FRIENDS.length; i++)
			{
				createFriendsItem(FRIENDS[i], i);
			}
			if(friendsItems.length == 0)
				noFriendsItems = true;
			friendsBgWrapper.sprite.visible = false;
		}
		
		private function createFriendsItem(itemId:String, num:Number):void
		{
			++friendsItemsLoaded;
			var friendObj:MovieClip = content[itemId];
					
			if(friendsItems.indexOf(itemId) == -1)// if player does not have that item
			{
				if(friendsItemsLoaded >= FRIENDS.length)
					allFriendsItemsLoaded();
				return;
			}
			var wrapper:BitmapWrapper = friendsBgWrapper.duplicate();
			var assetContainer:Sprite = new Sprite();
			assetContainer.name = CONTAINER;
			assetContainer.scaleX = assetContainer.scaleY = 1;
			
			var txt:TextField = TextUtils.cloneTextField(friendsInventory["friendNameText"]);
			txt.text = FRIENDS[num];
			assetContainer.addChild(txt);
			
			wrapper.sprite.addChild(assetContainer);
			
			var entity:Entity = EntityUtils.createMovingEntity( this, wrapper.sprite, friendsInventory );
			var interaction:Interaction = InteractionCreator.addToEntity( entity, ["click"], wrapper.sprite ); 
			interaction.click.add(clickFriendsItem);
			ToolTipCreator.addUIRollover(entity);
			friendsGridCreator.addSlotEntity( friendsGrid, entity, friendsInventoryBounds );
			entity.add( new Id(itemId) );
			
			if(friendsItemsLoaded >= ALL_ITEMS.length)
				allFriendsItemsLoaded();
		}
		
		private function allFriendsItemsLoaded():void
		{
			if(!noFriendsItems)
				GridControlScrollable(friendsGrid.get(GridControlScrollable)).refreshPositions = true;
			DisplayObject(super.screen).visible = true;
			super.groupReady();
		}
		
		private function clickFriendsItem(item:Entity):void
		{
			
		}
		//////////////////////////////////////////////////////////////////////////////////////////////
		//////////////////////////////////////////// CHATS ///////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////////
		
		private function setUpChatsBox():void
		{	
			chatsInventory = content.chatsInventory;
			chatsBgWrapper = super.convertToBitmapSprite(chatsInventory.itemUIBackground,chatsInventory.itemUIBackground.parent, false);
			
			chatsGridCreator = new GridScrollableCreator();
			chatsItemsLoaded = 0;
			chatsItems = [];
			
			for (var j:int = 0; j < ALL_ITEMS.length; j++) 
			{
				chatsItems.push(ALL_ITEMS[j]);
			}
			
			if(chatsItems.length == 0)
				noChatsItems = true;
			
			chatsInventory.removeChild(chatsInventory.itemUIBackground);
			var ref:MovieClip = content.chatsRef;
			
			chatsInventoryBounds = ref.getBounds(chatsInventory);
			chatsInventoryBounds.x = chatsInventoryBounds.y = 0;
			chatsInventory.mask = ref;			
			
			chatsGrid = chatsGridCreator.create( chatsInventoryBounds, chatsBgWrapper.sprite.getBounds(chatsBgWrapper.sprite), 1, 0, this, 5, false, null, 0, "chats_grid");
			chatsRatio = chatsGrid.get( Ratio );
			GridControlScrollable(chatsGrid.get(GridControlScrollable)).createSlots( chatsItems.length, 0, 1);
			for (var i:int = 0; i < ALL_ITEMS.length; i++)
			{
				createChatsItem(ALL_ITEMS[i], i);
			}
			if(chatsItems.length == 0)
				noChatsItems = true;
			chatsBgWrapper.sprite.visible = false;
		}
		
		private function createChatsItem(itemId:String, num:Number):void
		{
			++chatsItemsLoaded;
			
			if(chatsItems.indexOf(itemId) == -1)// if player does not have that item
			{
				if(chatsItemsLoaded >= ALL_ITEMS.length)
					allChatsItemsLoaded();
				return;
			}
			var wrapper:BitmapWrapper = chatsBgWrapper.duplicate();
			var assetContainer:Sprite = new Sprite();
			assetContainer.name = CONTAINER;
			assetContainer.scaleX = assetContainer.scaleY = 1;
			
			
			var nametxt:TextField = TextUtils.cloneTextField(chatsInventory["chatNameText"]);
			nametxt.text = FRIENDS[num];
			assetContainer.addChild(nametxt);
			var contenttxt:TextField = TextUtils.cloneTextField(chatsInventory["chatContentText"]);
			contenttxt.text = CHATS[num];
			
			assetContainer.addChild(contenttxt);
			wrapper.sprite.addChild(assetContainer);
			
			var entity:Entity = EntityUtils.createMovingEntity( this, wrapper.sprite, chatsInventory );
			var interaction:Interaction = InteractionCreator.addToEntity( entity, ["click"], wrapper.sprite ); 
			interaction.click.add(clickChatsItem);
			ToolTipCreator.addUIRollover(entity);
			chatsGridCreator.addSlotEntity( chatsGrid, entity, chatsInventoryBounds );
			entity.add( new Id(itemId) );
			
			if(chatsItemsLoaded >= ALL_ITEMS.length)
				allChatsItemsLoaded();
		}
		
		private function allChatsItemsLoaded():void
		{
			if(!noChatsItems)
				GridControlScrollable(chatsGrid.get(GridControlScrollable)).refreshPositions = true;
			DisplayObject(super.screen).visible = true;
			super.groupReady();
		}
		
		private function clickChatsItem(item:Entity):void
		{
			
		}
		
		//////////////////////////////////////////////////////////////////////////////////////////////
		//////////////////////////////////////////// COSTUMES ////////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////////
		
		private function setUpCostumeBox():void
		{	
			costumeInventory = content.costumeInventory;
			costumeBgWrapper = super.convertToBitmapSprite(costumeInventory.itemUIBackground,costumeInventory.itemUIBackground.parent, false);
			
			costumeGridCreator = new GridScrollableCreator();
			costumeItemsLoaded = 0;
			costumeItems = [];
			
			for (var j:int = 0; j < LOOKS.length; j++) 
			{
				costumeItems.push(j.toString());
			}
			
			if(costumeItems.length == 0)
				noCostumeItems = true;
			
			costumeInventory.removeChild(costumeInventory.itemUIBackground);
			var ref:MovieClip = content.costumeRef;
			
			costumeInventoryBounds = ref.getBounds(costumeInventory);
			costumeInventoryBounds.x = costumeInventoryBounds.y = 0;
			costumeInventory.mask = ref;			
			costumeGrid = costumeGridCreator.create( costumeInventoryBounds, costumeBgWrapper.sprite.getBounds(costumeBgWrapper.sprite), 4, 1, this, 0, true, null, 0, "costume_grid");
			costumeRatio = costumeGrid.get( Ratio );
			GridControlScrollable(costumeGrid.get(GridControlScrollable)).createSlots( costumeItems.length, 1, 0);
			for (var i:int = 0; i < LOOKS.length; i++)
			{
				createCostumeItem(i.toString());
			}
			if(costumeItems.length == 0)
				noCostumeItems = true;
			costumeBgWrapper.sprite.visible = false;
		}
		
		private function createCostumeItem(itemId:String):void
		{
			++costumeItemsLoaded;
			
			if(costumeItems.indexOf(itemId) == -1)// if player does not have that item
			{
				if(costumeItemsLoaded >= LOOKS.length)
					allCostumeItemsLoaded();
				return;
			}
			var wrapper:BitmapWrapper = costumeBgWrapper.duplicate();
			var assetContainer:Sprite = new Sprite();
			var type:String = CharacterCreator.TYPE_DUMMY;
			
			var num:Number = Number(itemId);
			var lookData:LookData = new LookData();
			lookData.applyLook( LOOKS[num][0], LOOKS[num][1], LOOKS[num][2], LOOKS[num][3], LOOKS[num][4], LOOKS[num][5], LOOKS[num][6], LOOKS[num][7], LOOKS[num][8], LOOKS[num][9], LOOKS[num][10], LOOKS[num][11], LOOKS[num][12], LOOKS[num][13], LOOKS[num][14], LOOKS[num][15] );
			var npc:Entity = charGroup.createDummy("npclist"+num, lookData, "left", "", assetContainer, this, stillNPCLoaded,false,0.5,type,new Point(0, 90));
			
			assetContainer.name = CONTAINER; //dont'think I need these three lines...
			assetContainer.scaleX = assetContainer.scaleY = .6;
			wrapper.sprite.addChild(assetContainer);
			
			var entity:Entity = EntityUtils.createMovingEntity( this, wrapper.sprite, costumeInventory );
			var interaction:Interaction = InteractionCreator.addToEntity( entity, ["click"], wrapper.sprite ); 
			interaction.click.add(clickCostumeItem);
			ToolTipCreator.addUIRollover(entity);
			costumeGridCreator.addSlotEntity( costumeGrid, entity, costumeBgWrapper.sprite.getBounds(costumeBgWrapper.sprite) );
			entity.add( new Id(itemId) );
			
			if(costumeItemsLoaded >= LOOKS.length)
				allCostumeItemsLoaded();
		}
		
		private function allCostumeItemsLoaded():void
		{
			if(!noCostumeItems)
				GridControlScrollable(costumeGrid.get(GridControlScrollable)).refreshPositions = true;
			DisplayObject(super.screen).visible = true;
			super.groupReady();
		}
		
		private function clickCostumeItem(item:Entity):void
		{
			var uiGroup:SceneUIGroup = super.parent.getGroupById( SceneUIGroup.GROUP_ID ) as SceneUIGroup;
			var num:Number = 2;
			var lookData:LookData = new LookData();
			lookData.applyLook( LOOKS[num][0], LOOKS[num][1], LOOKS[num][2], LOOKS[num][3], LOOKS[num][4], LOOKS[num][5], LOOKS[num][6], LOOKS[num][7], LOOKS[num][8], LOOKS[num][9], LOOKS[num][10], LOOKS[num][11], LOOKS[num][12], LOOKS[num][13], LOOKS[num][14], LOOKS[num][15] );
			
			var costumizer:Costumizer = new Costumizer( null, lookData, false, true);
			//costumizer.delegate = delegate;
			//initFullScreenPopup( costumizer );
			super.addChildGroup( costumizer );
			costumizer.init( super.groupContainer);
			//popup.popupRemoved.addOnce(onFullScreenPopupClosed);
		}
		
		private function setupSlider(container:MovieClip, slider:Entity, bar:Entity, rect:Rectangle, ratio:Ratio=null):void
		{			
			slider = EntityUtils.createSpatialEntity(this, container.slider);
			InteractionCreator.addToEntity(slider, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
			var draggable:Draggable = new Draggable("x");
			slider.add(draggable);
			slider.add(new Slider());
			slider.add(new MotionBounds(rect));
			if(ratio){
				slider.add(ratio);
			}
			ToolTipCreator.addToEntity(slider);
			draggable.drop.add( onSliderRelease );
			bar = EntityUtils.createSpatialEntity(this, container.bar);
			var interaction:Interaction = InteractionCreator.addToEntity(bar, [InteractionCreator.CLICK]);
			interaction.click.add(this.onBarClicked);
			ToolTipCreator.addToEntity(bar);
		}
		
		private function onBarClicked(entity:Entity):void
		{
			var display:DisplayObject = friendsBar.get(Display).displayObject;
			var box:Rectangle = friendsSlider.get(MotionBounds).box;
			friendsRatio.decimal = Utils.toDecimal(display.mouseX, box.left, box.right);
		}
		
		private function onSliderRelease( entity:Entity = null ):void 
		{
			//if ( _gridControl.canScroll ) 
			//{
			//activePage.savedGridPercent = _ratio.decimal;
			//}
		}
		
		public function capFirsts(txt:String):String
		{
			return txt.replace(/\b./g,function(...m):String{return m[0].toUpperCase()});
		}
	};
};