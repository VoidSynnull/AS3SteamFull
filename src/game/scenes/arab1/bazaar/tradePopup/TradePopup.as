package game.scenes.arab1.bazaar.tradePopup
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
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.ui.GridControlScrollable;
	import game.components.ui.ScrollBox;
	import game.creators.entity.character.CharacterCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.GridScrollableCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.character.LookData;
	import game.data.display.BitmapWrapper;
	import game.scene.template.CharacterGroup;
	import game.scene.template.ItemGroup;
	import game.systems.ui.ScrollBoxSystem;
	import game.ui.popup.Popup;
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
		public function TradePopup(container:DisplayObjectContainer=null, shopNumber:uint = 1, traderLook:LookData = null)
		{
			super(container);
			this.shopNumber = shopNumber;
			itemsLoaded = 0;
			this.traderLook = traderLook;
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);
			
			this.pauseParent 		= true;
			this.darkenBackground 	= true;
			this.autoOpen 			= true;
			this.groupPrefix = "scenes/arab1/bazaar/tradePopup/";
			this.screenAsset = "tradePopup.swf";
			
			this.load();
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
			DisplayObject(super.screen).visible = false;
			
			addSystem(new ScrollBoxSystem());
			
			content = screen.content;
			
			this.letterbox(content, new Rectangle(0, 0, 960, 640));
			
			this.bitmapAssets();
			
			npcPosition = content.npc;
			var charGroup:CharacterGroup = new CharacterGroup();
			charGroup.setupGroup(this, content);
			
			var type:String = CharacterCreator.TYPE_DUMMY;
			if(PlatformUtils.isMobileOS)
				type = CharacterCreator.TYPE_PORTRAIT;
			
			charGroup.createDummy("trader", traderLook, "left", "", content, this,traderLoaded,false,1.25,type,new Point(761, 435));
			
			trader = new Dictionary();
			this[SET_UP_TRADER+shopNumber]();
			
			itemGroup = getGroupById(ItemGroup.GROUP_ID) as ItemGroup;
			
			setUpContent();
			
			createButtons();
			
			loadCloseButton();
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
				var dialog:Dialog = npc.get(Dialog);
				dialog.say("a wise trade my friend.");
				SceneUtil.delay(this, 3, completeTrade);
				SceneUtil.lockInput(this);
			}
			else
				clickItem(getEntityById(itemId));
			
			showButtons(false, PlatformUtils.isMobileOS);
		}
		
		private function completeTrade(...args):void
		{
			super.close();
			SceneUtil.lockInput(this, false);
		}
		
		private function tradeComplete(group:Group, itemId:String, tradeId:String):void
		{
			if(itemId != SALT)
				shellApi.removeItem(itemId);
			shellApi.getItem(tradeId, null, true);
		}
		
		private function traderLoaded(entity:Entity):void
		{
			npc = entity;
			DisplayUtils.moveToOverUnder(EntityUtils.getDisplayObject(npc), npcPosition, false);
			CharUtils.assignDialog(npc, this, "", false, -1.5, .5 );
			
			Dialog(npc.get(Dialog)).container = content;
			
			if(noItems)
				Dialog(npc.get(Dialog)).say("come back when you've got something to trade.");
			
			if(itemsLoaded >= ALL_ITEMS.length || noItems)
			{
				SceneUtil.addTimedEvent(this, new TimedEvent(4,1,allItemsLoaded)).countByUpdate = true;
			}
		}
		
		private function setUpTrader1():void
		{
			trader[SALT] = CLOTH;
			trader[CLOTH] = SALT;
			trader[GRAIN] = LAMP;
			trader[LAMP] = GRAIN;
			trader[PEARL] = IVORY_CAMEL;
			trader[IVORY_CAMEL] = PEARL;
		}
		
		private function setUpTrader2():void
		{
			trader[SALT] = GRAIN;
			trader[GRAIN] = SALT;
			trader[CLOTH] = SPY_GLASS;
			trader[SPY_GLASS] = CLOTH;
			trader[CROWN_JEWEL] = IVORY_CAMEL;
			trader[IVORY_CAMEL] = CROWN_JEWEL;
		}
		
		private function setUpTrader3():void
		{
			trader[CLOTH] = GRAIN;
			trader[GRAIN] = CLOTH;
			trader[CROWN_JEWEL] = PEARL;
			trader[PEARL] = CROWN_JEWEL;
			trader[IVORY_CAMEL] = CAMEL_HARNESS;
			trader[CAMEL_HARNESS] = IVORY_CAMEL;
		}
		
		private function setUpContent():void
		{
			inventory = content.inventory;
			
			itemsLoaded = 0;
			itemAssetPrefix = shellApi.assetPrefix + "items/arab1/";
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
				if(item != SALT_TRADE)
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
			
			// salt is a special case where the trding asset and the card item are not the same
			if(itemId != SALT)
			{
				assetSprite = BitmapUtils.createBitmapSprite(asset);
				assetEntity = EntityUtils.createSpatialEntity(this, assetSprite, traderItem);
				if(itemId == SALT_TRADE)
					assetEntity.add(new Id(itemId));
				else
					assetEntity.add(new Id(itemId+TRADE));
				EntityUtils.visible(assetEntity, false,true);
			}
			
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
			var interaction:Interaction = InteractionCreator.addToEntity( bundleEntity, ["click"], wrapper.sprite ); 
			interaction.click.add(clickItem);
			ToolTipCreator.addUIRollover(bundleEntity);
			gridCreator.addSlotEntity( tradeGrid, bundleEntity, inventoryBounds );
			bundleEntity.add( new Id(itemId) );
			
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
				Dialog(npc.get(Dialog)).say("No, I am not willing to trade anything for that " + toProperName(itemId) + ".");
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
		
		private function agreeToTrade($itemId:String, $tradeItemId:String):void{
			switch($tradeItemId){
				case GRAIN:
					Dialog(npc.get(Dialog)).say("You have a seasoned sense for a good bargain! Your salt for this sack of grain?");
					break;
				case CLOTH:
					Dialog(npc.get(Dialog)).say("You can't get more wrapped up in a better deal! Do we have a trade?");
					break;
				case IVORY_CAMEL:
					Dialog(npc.get(Dialog)).say("Why, I'd even trade my beloved camel for this!");
					break;
				case PEARL:
					Dialog(npc.get(Dialog)).say("You are very smart to bring this to me. How about this fine pearl to go with your wisdom?");
					break;
				case SPY_GLASS:
					Dialog(npc.get(Dialog)).say("One can see this is a great steal from far away! Wouldn't you agree?");
					break;
				case CAMEL_HARNESS:
					Dialog(npc.get(Dialog)).say("I can't believe what I am seeing, and it doesn't bite! My camel for this?");
					break;
				default:
					Dialog(npc.get(Dialog)).say("Yes, I would be willing to trade your " + toProperName($itemId) + " for this " + toProperName($tradeItemId) + ".");
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
		
		private const OFFSET_X:Number = 500;
		
		private var itemAssetPrefix:String;
		
		private var items:Array;
		
		private var traderLook:LookData;
		
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
		
		private const CAMEL_HARNESS:String			= "camel_harness";
		private const CLOTH:String					= "cloth";
		private const CROWN_JEWEL:String			= "crown_jewel";
		private const GRAIN:String					= "grain";
		private const IVORY_CAMEL:String			= "ivory_camel";
		private const LAMP:String					= "lamp";
		private const PEARL:String					= "pearl";
		private const SPY_GLASS:String				= "spy_glass";
		private const SALT:String					= "salt";
		private const SALT_TRADE:String				= "salt_trade";
		
		private var buttonText:Dictionary;
		
		private var noItems:Boolean = false;
		
		private const ALL_ITEMS:Vector.<String> = new <String>[CAMEL_HARNESS, CLOTH, CROWN_JEWEL, GRAIN, IVORY_CAMEL, LAMP, PEARL, SPY_GLASS, SALT, SALT_TRADE];
		
		private var trader:Dictionary;
		private var npc:Entity;
	}
}