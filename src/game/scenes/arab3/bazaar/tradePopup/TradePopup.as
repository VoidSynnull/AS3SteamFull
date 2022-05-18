package game.scenes.arab3.bazaar.tradePopup
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.ui.GridControlScrollable;
	import game.components.ui.ScrollBox;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.GridScrollableCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.character.LookData;
	import game.data.display.BitmapWrapper;
	import game.data.scene.characterDialog.DialogParser;
	import game.scene.template.CharacterDialogGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.GameScene;
	import game.scene.template.ItemGroup;
	import game.systems.ui.ScrollBoxSystem;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.ColorUtil;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TextUtils;
	import game.util.TweenUtils;
	
	public class TradePopup extends Popup
	{
		
		public const SLIDE_CRYSTAL_SOUND:String = SoundManager.EFFECTS_PATH +"concrete_drag_01.mp3";
		public const SLIDE_OIL_SOUND:String = SoundManager.EFFECTS_PATH +"small_splash_01.mp3";
		public const SLIDE_BURLAP_SOUND:String = SoundManager.EFFECTS_PATH +"smooth_surface_drag_02.mp3";
		public const SLIDE_BONE_SOUND:String = SoundManager.EFFECTS_PATH +"pick_up_wrapper_01.mp3";
		public const SLIDE_MOON_SOUND:String = SoundManager.EFFECTS_PATH +"grinding_stone_02.mp3";
		
		public const MAKE_TRADE_SOUND:String = SoundManager.EFFECTS_PATH +"purchase_01.mp3";
		public const REJECT_TRADE_SOUND:String = SoundManager.EFFECTS_PATH +"miss_points_01.mp3";
		
		public function TradePopup(container:DisplayObjectContainer=null, shopNumber:uint = 1, traderLook:LookData = null)
		{
			super(container);
			this.shopNumber = shopNumber;
			itemsLoaded = 0;
			//this.traderLook = traderLook;
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);
			
			this.pauseParent 		= true;
			this.darkenBackground 	= true;
			this.autoOpen 			= true;
			this.groupPrefix = "scenes/arab3/bazaar/tradePopup/";
			//this.screenAsset = "tradePopup.swf";
			
			this.load();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.loadFiles([GameScene.NPCS_FILE_NAME,GameScene.DIALOG_FILE_NAME,"tradePopup.swf"], false, true, loaded);
		}	
		
		override public function destroy():void
		{
			trader = null;
			items = null;
			gridCreator = null;
			if(!noItems)
				_itemBgWrapper.destroy();
			
			super.destroy();
		}
		
		override public function loaded():void
		{
			preparePopup();
			
			addSystem(new ScrollBoxSystem());
			
			super.screen = super.getAsset("tradePopup.swf", true) as MovieClip;
			DisplayObject(super.screen).visible = false;
			
			content = screen.content;
			
			this.letterbox(content, new Rectangle(0, 0, 960, 640));
			
			this.bitmapAssets();
			
			npcPosition = content.npc;
			//var charGroup:CharacterGroup = new CharacterGroup();
			//charGroup.setupGroup(this, content);
			
			//var type:String = CharacterCreator.TYPE_DUMMY;
			//if(PlatformUtils.isMobileOS)
			//type = CharacterCreator.TYPE_PORTRAIT;
			
			//charGroup.createDummy("trader", traderLook, "left", "", content, this,traderLoaded,false,1.25,type,new Point(npcPosition.x, npcPosition.y + 200));
			setupCharacters();
			super.loadCloseButton();
			super.loaded();	
		}
		
		private function bitmapAssets():void
		{
			var clip:MovieClip;
			
			this.convertToBitmap(content["wall1"]);
			this.convertToBitmap(content["wall2"]);
			this.convertToBitmap(content["backdrop"]);
			this.convertToBitmap(content["inventoryBackground"]);
			
			clip = content["background"];
			clip.gotoAndStop(shopNumber);
			this.convertToBitmap(clip);
			
			clip = content["table"];
			clip.gotoAndStop(shopNumber);
			this.convertToBitmap(clip);
		}
		
		public function setupCharacters():void
		{
			//load chars
			var characterGroup:CharacterGroup = new CharacterGroup();
			var characterDialogGroup:CharacterDialogGroup = new CharacterDialogGroup();
			
			characterGroup.setupGroup( this, npcPosition, super.getData( GameScene.NPCS_FILE_NAME ), allCharactersLoaded);		
			characterDialogGroup.setupGroup( this, super.getData( GameScene.DIALOG_FILE_NAME ), npcPosition);
		}
		
		protected function allCharactersLoaded():void
		{
			trader = new Dictionary();
			switch(shopNumber)
			{
				case 1:
				{
					setUpTrader1();
					break;
				}
				case 2:
				{
					setUpTrader2();
					break;
				}				
				case 3:
				{
					setUpTrader3();
					break;
				}
			}
			
			var dialog:Dialog = npc.get(Dialog);
			dialog.dialogPositionPercents = new Point(-1.55,0.56);
			dialog.faceSpeaker = false;
			dialog.container = npcPosition;
			DisplayUtils.moveToTop(npc.get(Display).displayObject);
			
			npc.remove(SceneInteraction);
			npc.remove(Interaction);
			ToolTipCreator.removeFromEntity(npc);
			
			itemGroup = getGroupById(ItemGroup.GROUP_ID) as ItemGroup;
			
			setUpContent();
			
			createButtons();		
		}
		
		
		private function createButtons():void
		{
			buttonText = new Dictionary();
			buttonText[CANCEL] = "no, thanks";
			buttonText[CONFIRM] = "deal!";
			var buttons:Array = [CANCEL, CONFIRM];
			for(var i:int = 0; i < buttons.length; i++)
			{
				var label:String = buttons[i];
				var clip:MovieClip = content[label];
				
				DisplayUtils.moveToTop(clip);
				
				formatText(clip.base.tf, buttonText[label]);
				
				if(label == CONFIRM)
					ColorUtil.colorize(clip.base.color, 0x22577A);
				
				this[label] = ButtonCreator.createButtonEntity(clip, this, Command.create(clickButton, label));
			}
			showButtons(false, true);
		}
		
		private function showButtons(show:Boolean, force:Boolean = false):void
		{
			if(show && !showingButtons)
			{
				ToolTipCreator.addUIRollover(confirm);
				ToolTipCreator.addUIRollover(cancel);
			}
			else
			{
				ToolTipCreator.removeFromEntity(confirm);
				ToolTipCreator.removeFromEntity(cancel);
			}
			
			var alpha:Number = 0;
			if(show)
				alpha = 1;
			
			if(force)
			{
				if(confirm.get(Tween))
				{
					confirm.remove(Tween);
					cancel.remove(Tween);
				}
				Display(confirm.get(Display)).alpha = alpha;
				Display(cancel.get(Display)).alpha = alpha;
			}
			else
			{
				TweenUtils.entityTo(cancel, Display, 1, {alpha:alpha});
				TweenUtils.entityTo(confirm, Display, 1, {alpha:alpha});
			}
			showingButtons = show;
		}
		
		private function formatText(tf:TextField, text:String):void
		{
			tf = TextUtils.refreshText(tf, TEXT_FONT);
			var format:TextFormat = new TextFormat(TEXT_FONT, 24, 0xFFFFFF);
			
			tf.setTextFormat(format);
			tf.defaultTextFormat = format;
			tf.text = text;
		}
		
		private function clickButton(button:Entity, label:String):void
		{
			if(!showingButtons)
				return;
			var itemId:String = tradingItem.get(Id).id;
			itemId = itemId.substring(0, itemId.length - TRADE.length);
			var tradeId:String = tradeForItem.get(Id).id;
			tradeId = tradeId.substr(0, tradeId.length - TRADE.length);
			
			if(label == CONFIRM)
			{
				removed.addOnce(Command.create(tradeComplete, itemId, tradeId));
				AudioUtils.play(this, MAKE_TRADE_SOUND, 1);
				var dialog:Dialog = npc.get(Dialog);
				dialog.say("a wise trade my friend.");
				dialog.complete.addOnce(completeTrade);
				SceneUtil.lockInput(this);
			}
			else{
				AudioUtils.play(this, REJECT_TRADE_SOUND, 1);
				clickItem(getEntityById(itemId));
			}
			
			showButtons(false, PlatformUtils.isMobileOS);
		}
		
		private function completeTrade(...args):void
		{
			super.close();
			SceneUtil.lockInput(this, false);
		}
		
		private function tradeComplete(group:Group, itemId:String, tradeId:String):void
		{
			if(itemId != CRYSTALS)
				shellApi.removeItem(itemId);
			shellApi.getItem(tradeId, null, true);
		}
		
		private function traderSetup(data:*):void
		{
			DisplayUtils.moveToOverUnder(EntityUtils.getDisplayObject(npc), npcPosition, false);
			CharUtils.assignDialog(npc, this, "", false, -1.5, .5 );
			var dialog:Dialog = npc.get(Dialog);
			dialog.allDialog = DialogParser(new DialogParser(this)).parse(data).trader;
			dialog.container = content;
			if(noItems){
				Dialog(npc.get(Dialog)).sayById("comeback");
			}
			
			if(itemsLoaded >= ALL_ITEMS.length || noItems)
			{
				SceneUtil.addTimedEvent(this, new TimedEvent(4,1,allItemsLoaded)).countByUpdate = true;
			}
		}
		
		private function setUpTrader1():void
		{
			npc = getEntityById("trade_trader1");
			removeEntity(getEntityById("trade_trader2"));
			removeEntity(getEntityById("trade_trader3"));
			trader[CRYSTALS] = BURLAP_SACK;
			trader[BURLAP_SACK] = CRYSTALS;
			trader[SESAME_OIL] = WISHBONE;
			trader[WISHBONE] = SESAME_OIL;
		}
		
		private function setUpTrader2():void
		{
			npc = getEntityById("trade_trader2");
			removeEntity(getEntityById("trade_trader1"));
			removeEntity(getEntityById("trade_trader3"));
			trader[BURLAP_SACK] = SESAME_OIL;
			trader[SESAME_OIL] = BURLAP_SACK;
			trader[WISHBONE] = MOONSTONE;
			trader[MOONSTONE] = WISHBONE;
		}
		
		private function setUpTrader3():void
		{
			npc = getEntityById("trade_trader3");
			removeEntity(getEntityById("trade_trader1"));
			removeEntity(getEntityById("trade_trader2"));
			trader[CRYSTALS] = SESAME_OIL;
			trader[SESAME_OIL] = CRYSTALS;
			trader[BURLAP_SACK] = MOONSTONE;
			trader[MOONSTONE] = BURLAP_SACK;
		}
		
		
		
		private function setUpContent():void
		{
			inventory = content.inventory;
			
			itemsLoaded = 0;
			itemAssetPrefix = shellApi.assetPrefix + "items/arab3/";
			items = [];
			
			var item:String;
			
			for (var j:int = 0; j < ALL_ITEMS.length; j++) 
			{
				item = ALL_ITEMS[j];
				if(shellApi.checkHasItem(item))
					items.push(item);
			}
			
			if(items.length == 0)
				noItems = true;
			
			var clip:MovieClip = inventory.itemUIBackground;
			
			_itemBgWrapper = super.convertToBitmapSprite(clip, clip.parent, false);
			inventory.removeChild(clip);
			
			playerItem = content.playerItem;
			traderItem = content.traderItem;
			
			var ref:MovieClip = content["bundleFrame_ref"];
			inventoryBounds = ref.getBounds(content);
			inventoryBounds.x = inventoryBounds.y = 0;
			inventory.mask = ref;
			
			gridCreator = new GridScrollableCreator();
			tradeGrid = gridCreator.create( inventoryBounds, _itemBgWrapper.sprite.getBounds(_itemBgWrapper.sprite), 1, 0, this, 10, false);
			tradeGrid.add(new ScrollBox( inventory, inventoryBounds, 100, 10, false, 60) );
			
			GridControlScrollable(tradeGrid.get(GridControlScrollable)).createSlots( items.length, 0, 1);
			for (var i:int = 0; i < ALL_ITEMS.length; i++)
			{
				item = ALL_ITEMS[i];
				if(item != CRYSTALS)
				{
					if(!shellApi.checkHasItem(item) && !canTradeForItem(item))
					{
						trace("TradePopup :: don't bother loading " + item);
						itemsLoaded++;
						continue;
					}
				}
				shellApi.loadFile(itemAssetPrefix + item +".swf", Command.create(createItem, item));
			}
			if(items.length == 0)
				noItems = true;
			_itemBgWrapper.sprite.visible = false;
		}
		
		private function canTradeForItem(item:String):Boolean
		{
			for(var i:int = 0; i < items.length; i ++)
			{
				if(trader[items[i]] == item)
					return true;
			}
			return false;
		}
		
		private function createItem(asset:MovieClip, itemId:String):void
		{
			++itemsLoaded;
			var assetSprite:Sprite;
			var assetEntity:Entity;
			trace(itemId);
			if(itemId == CRYSTALS)
			{
				// change to single crystal
				var clip:MovieClip = asset["crystals"];
				clip.gotoAndStop("gem, stop()");
				assetSprite = BitmapUtils.createBitmapSprite(clip);
				assetEntity = EntityUtils.createSpatialEntity(this, assetSprite, traderItem);
				clip.gotoAndStop("pile, stop()");
			}
			else
			{
				assetSprite = BitmapUtils.createBitmapSprite(asset);
				assetEntity = EntityUtils.createSpatialEntity(this, assetSprite, traderItem);
			}
			
			// REPOSITION SESAME_OIL TRADED ASSET SINCE CARD ART HAS BEEN MOVED
			if( itemId == SESAME_OIL )
			{
				Spatial( assetEntity.get( Spatial )).y -= 45;
			}
			assetEntity.add(new Id(itemId+TRADE));
			EntityUtils.visible(assetEntity, false,true);
			
			if(items.indexOf(itemId) == -1)// if player does not have that item
			{
				if(itemsLoaded >= ALL_ITEMS.length && npc != null)
					allItemsLoaded();
				return;
			}
			
			
			
			var wrapper:BitmapWrapper = _itemBgWrapper.duplicate();
			var assetContainer:Sprite = new Sprite();
			assetContainer.name = CONTAINER;
			assetContainer.scaleX = assetContainer.scaleY = .5;
			wrapper.sprite.addChild(assetContainer);
			
			assetSprite = BitmapUtils.createBitmapSprite(asset);
			assetEntity = EntityUtils.createSpatialEntity(this, assetSprite, assetContainer);
			
			assetEntity.add(new Id(itemId+ASSET));
			
			var bundleEntity:Entity = EntityUtils.createMovingEntity( this, wrapper.sprite, inventory );
			var interaction:Interaction = InteractionCreator.addToEntity( bundleEntity, [InteractionCreator.CLICK], wrapper.sprite ); 
			interaction.click.add(clickItem);
			ToolTipCreator.addUIRollover(bundleEntity);
			gridCreator.addSlotEntity( tradeGrid, bundleEntity, inventoryBounds );
			bundleEntity.add( new Id(itemId) );
			
			// REPOSITION SESAME_OIL UI SELECTION SINCE CARD ART HAS BEEN MOVED
			if( itemId == SESAME_OIL )
			{
				Spatial( assetEntity.get( Spatial )).y -= 17;
			}
			
			if(itemsLoaded >= ALL_ITEMS.length && npc != null)
				allItemsLoaded();
		}
		
		private function allItemsLoaded():void
		{
			if(!noItems)
				GridControlScrollable(tradeGrid.get(GridControlScrollable)).refreshPositions = true;
			DisplayObject(super.screen).visible = true;
			super.groupReady();
		}
		
		private function clickItem(item:Entity):void
		{
			var itemId:String;
			var asset:Entity;
			if(tradingItem != null)
			{
				itemId = Id(tradingItem.get(Id)).id;
				itemId = itemId.substring(0,itemId.length-TRADE.length);
				asset = getEntityById(itemId +ASSET);
				Display(asset.get(Display)).alpha = 1;
				EntityUtils.visible(tradingItem, false);
			}
			
			if(tradeForItem != null)
			{
				EntityUtils.visible(tradeForItem, false);
				tradeForItem = null;
			}
			
			itemId = Id(item.get(Id)).id;
			asset = getEntityById(itemId+TRADE);
			
			if(tradingItem == asset)
			{
				tradingItem = null;
				showButtons(false, PlatformUtils.isMobileOS);
				return;
			}
			playItemSound(itemId);
			tradingItem = asset;
			EntityUtils.visible(tradingItem);
			Display(tradingItem.get(Display)).setContainer(playerItem);
			if(!PlatformUtils.isMobileOS)
			{
				
				Spatial(tradingItem.get(Spatial)).x = -OFFSET_X;
				TweenUtils.entityTo(tradingItem, Spatial, 1, {x:0});
			}
			
			// dim asset
			asset = getEntityById(itemId +ASSET);
			Display(asset.get(Display)).alpha = .5;
			
			var tradeItemId:String = trader[itemId];
			
			EntityUtils.removeAllWordBalloons(this, npc);
			
			if(tradeItemId == null)
			{
				var tense:String = toProperName(itemId);
				if(tense == CRYSTALS){
					itemId = itemId.substr(0,itemId.length - 1);
				}
				var dialog:Dialog = Dialog(npc.get(Dialog));
				dialog.replaceKeyword("ITEM_N",toProperName(itemId));
				dialog.sayById("nothing");
				showButtons(false);
				return;
			}
			
			showButtons(true, PlatformUtils.isMobileOS);
			
			agreeToTrade(itemId, tradeItemId);
			
			tradeForItem = getEntityById(tradeItemId+TRADE);
			Display(tradeForItem.get(Display)).setContainer(traderItem);
			EntityUtils.visible(tradeForItem);
			if(!PlatformUtils.isMobileOS)
			{
				Spatial(tradeForItem.get(Spatial)).x = OFFSET_X;
				TweenUtils.entityTo(tradeForItem, Spatial, 1, {x:0});
			}
		}
		
		private function playItemSound(tradeItemId:String):void
		{
			switch(tradeItemId)
			{
				case CRYSTALS:
				{
					AudioUtils.play(this, SLIDE_CRYSTAL_SOUND, 1.2);
					break;
				}
				case SESAME_OIL:
				{
					AudioUtils.play(this, SLIDE_OIL_SOUND, 1.2);
					break;
				}				
				case BURLAP_SACK:
				{
					AudioUtils.play(this, SLIDE_BURLAP_SOUND, 1.2);
					break;
				}				
				case WISHBONE:
				{
					AudioUtils.play(this, SLIDE_BONE_SOUND, 1.2);
					break;
				}
				case MOONSTONE:
				{
					AudioUtils.play(this, SLIDE_MOON_SOUND, 1.2);
					break;
				}
			}
		}
		
		private function agreeToTrade(itemId:String, tradeItemId:String):void{
			var dialog:Dialog = npc.get(Dialog);
			switch(tradeItemId){
				case BURLAP_SACK:
					dialog.sayById("burlap");
					break;
				case SESAME_OIL:
					dialog.sayById("sesame");
					break;
				case MOONSTONE:
					dialog.sayById("moon");
					break;
				case WISHBONE:
					dialog.sayById("bone");
					break;
				default:
					var tense:String = toProperName(tradeItemId);
					if(tense == CRYSTALS){
						tradeItemId = tradeItemId.substr(0,tradeItemId.length - 1);
					}
					dialog.replaceKeyword("ITEM_Y",toProperName(itemId));
					dialog.replaceKeyword("TRADEI",toProperName(tradeItemId));
					dialog.sayById("other");
					break;
			}
		}
		
		private function toProperName(name:String):String
		{
			var index:int = name.indexOf("_");
			if(index > -1)
			{
				var before:String = name.substr(0, index);
				var after:String = name.substr(index + 1);
				name = before + " " + after;
			}
			return name;
		}
		
		private function makeEntity( clip:MovieClip, play:Boolean = true, sequence:BitmapSequence = null ):Entity
		{
			if( sequence )
			{
				var target:Entity = EntityUtils.createMovingTimelineEntity(this, clip, null, play);
				target = BitmapTimelineCreator.convertToBitmapTimeline(target, clip, true, sequence, 3);
			}
			else
			{
				var wrapper:BitmapWrapper = super.convertToBitmapSprite( clip, null, true, 3 );
				target = EntityUtils.createSpatialEntity( this, wrapper.sprite );
			}
			
			target.add( new Id( clip.name ));
			return target; 
		}
		
		private const OFFSET_X:Number = 500;
		
		private var itemAssetPrefix:String;
		
		private var items:Array;
		
		//private var traderLook:LookData;
		
		private var itemGroup:ItemGroup;
		private var content:MovieClip;
		private var shopNumber:uint;
		private var _itemBgWrapper:BitmapWrapper;
		private var inventory:MovieClip;
		private var itemsLoaded:uint;
		private var gridCreator:GridScrollableCreator;
		private var tradeGrid:Entity;
		private var inventoryBounds:Rectangle;
		private var playerItem:MovieClip;
		private var traderItem:MovieClip;
		private var npcPosition:MovieClip;
		
		private var tradingItem:Entity;
		private var tradeForItem:Entity;
		
		private var confirm:Entity;
		private var cancel:Entity;
		private var showingButtons:Boolean = false;
		
		private const SET_UP_TRADER:String 			= "setUpTrader";
		private const ASSET:String 					= "Asset";
		private const CONTAINER:String 				= "container";
		private const TRADE:String 					= "_trade";
		
		private const CONFIRM:String				= "confirm";
		private const CANCEL:String					= "cancel";
		
		private const TEXT_FONT:String 				= "CreativeBlock BB";
		
		public const BURLAP_SACK:String			=	"burlap_sack";
		public const CRYSTALS:String 			= 	"crystals";
		public const MOONSTONE:String 			=	"moonstone";
		public const SESAME_OIL:String 			=	"sesame_oil";
		public const WISHBONE:String 			=	"wishbone";	
		
		private var buttonText:Dictionary;
		
		private var noItems:Boolean = false;
		
		private const ALL_ITEMS:Vector.<String> = new <String>[BURLAP_SACK,CRYSTALS,MOONSTONE,SESAME_OIL,WISHBONE];
		
		private var trader:Dictionary;
		private var npc:Entity;
	}
}

