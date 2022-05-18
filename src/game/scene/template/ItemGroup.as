package game.scene.template
{
	import flash.display.DisplayObjectContainer;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Tween;
	import engine.group.Group;
	import engine.group.Scene;
	
	import game.creators.scene.SceneItemCreator;
	import game.data.game.GameEvent;
	import game.data.item.SceneItemData;
	import game.data.item.SceneItemParser;
	import game.data.scene.labels.LabelData;
	import game.systems.SystemPriorities;
	import game.systems.hit.ItemHitSystem;
	import game.ui.showItem.ShowItem;
	import game.util.DataUtils;
	
	import org.osflash.signals.Signal;
	
	/**
	 * Manages retrievable items within a scene.
	 */
	public class ItemGroup extends Group
	{
		public function ItemGroup()
		{
			super();
			this.id = GROUP_ID;
			_cardQueue = new Vector.<Object>();
			_itemsLoaded = new Signal();
		}
		
		override public function destroy():void
		{			
			_itemContainer = null;
			_overlayContainer = null;
			super.destroy();
		}
		
		public function setupScene(scene:Scene, xml:XML = null, itemContainer:DisplayObjectContainer = null, callback:Function = null):void
		{			
			_overlayContainer = scene.overlayContainer;
			_itemContainer = itemContainer;
			
			// add it as a child group to give it access to systemManager.
			scene.addChildGroup(this);

			// create/add ShowItem group
			_showItemGroup = super.addChildGroup(new ShowItem(_overlayContainer)) as ShowItem;
			
			// NOTE :: callback needs to be fired even if xml is null, so that loading sequence can complete.
			addItems(xml, callback);

			super.shellApi.eventTriggered.add(onEventTriggered);
		}
		
		/**
		 * Add all items to scene based on the scene's itemXml
		 */
		public function addItems(itemXml:XML, callback:Function = null):void
		{
			if(itemXml != null)
			{
				var sceneItemParser:SceneItemParser = new SceneItemParser();
				_allItemData = sceneItemParser.parse(itemXml);
				
				for each (var itemData:SceneItemData in _allItemData)
				{
					if((itemData.event == GameEvent.DEFAULT && itemData.triggeredByEvent == null) || super.shellApi.checkEvent(itemData.event))
					{
						if(!super.shellApi.checkItemEvent(itemData.id))
						{
							if(itemData.collection)
							{
								var currentCollection:String = shellApi.getUserField(itemData.collection, shellApi.island);
								if(!DataUtils.validString(currentCollection) || currentCollection.indexOf(itemData.id) != -1)
										continue;
							}
							addSceneItemByData(itemData, false);
						}
					}
				}
			}

			if(callback != null)
			{
				if(_itemsLoading < 1)
				{
					callback();
				}
				else
				{
					_itemsLoaded.addOnce(callback);
				}
			}
		}
		
		/**
		 * Add a single item, derived from SceneItemData, to scene.
		 * This assumes scene item is an external asset that needs to be loaded into the scene.
		 * Add ItemHitSystem if not already add and links item dispatch to private handler.
		 */
		public function addSceneItemByData(data:SceneItemData, fadeIn:Boolean = false):void
		{
			var itemAssetPath:String = super.shellApi.assetPrefix + "scenes/" + super.shellApi.island + "/items/";
			
			if(_sceneItemCreator == null)
			{
				_sceneItemCreator = new SceneItemCreator();
			}
			
			super.shellApi.loadFile(itemAssetPath + data.asset, sceneItemLoaded, data, fadeIn);
			
			addItemHitSystem();
			
			_itemsLoading++;
		}
		
		public function addSceneItemFromDisplay( itemDisplay:DisplayObjectContainer, id:String, labelData:LabelData = null, bitmapItem:Boolean = false, fadeIn:Boolean = false):Entity
		{
			if(_sceneItemCreator == null)
			{
				_sceneItemCreator = new SceneItemCreator();
			}
			
			var sceneItemData:SceneItemData = new SceneItemData();
			if( labelData == null )
			{
				sceneItemData.label = new LabelData( "click" );
				//sceneItemData.label = new LabelData( "click", "Examine" );
			}
			sceneItemData.x = itemDisplay.x;
			sceneItemData.y = itemDisplay.y;	
			sceneItemData.id = id;

			var entity:Entity = _sceneItemCreator.create(itemDisplay, sceneItemData, super.parent, bitmapItem );
			
			if(fadeIn)
			{
				var display:Display = entity.get(Display);
				display.alpha = 0;
				var tween:Tween = new Tween();
				entity.add(tween);
				tween.to(display, 1, { alpha : 1 });
			}
			
			return entity;
		}
		
		/**
		 * Setup the ItemHitSystem, creates system and setup us callback.
		 * 
		 */
		public function addItemHitSystem():void
		{
			if(!super.parent.getSystem(ItemHitSystem))	// items require ItemHitSystem, add system if not yet added
			{
				var itemHitSystem:ItemHitSystem = new ItemHitSystem();
				super.parent.addSystem(itemHitSystem, SystemPriorities.resolveCollisions);
				itemHitSystem.gotItem.add(itemHit);
			}
		}
		
		public function itemHit(entity:Entity):void
		{
			showAndGetItem(entity.get(Id).id, null, null, null, entity);
		}
		
		/**
		 * Handler for when item asset load has completed.
		 * Create Entity for item. 
		 */
		private function sceneItemLoaded(itemDisplay:DisplayObjectContainer, data:SceneItemData, fadeIn:Boolean = false):void
		{
			_itemContainer.addChild(itemDisplay);
			var entity:Entity = _sceneItemCreator.create(itemDisplay, data, super.parent);
			
			if(fadeIn)
			{
				var display:Display = entity.get(Display);
				display.alpha = 0;
				var tween:Tween = new Tween();
				entity.add(tween);
				tween.to(display, 1, { alpha : 1 });
			}
			
			_itemsLoading--;
			
			if(_itemsLoading < 1)
			{
				_itemsLoaded.dispatch();
			}
		}
		
		/**
		 * Give item to player and show item, will only show item if the item given to player.
		 * If player already has item the item will not be shown.
		 * @param itemID
		 * @param type
		 * @param transitionCompleteHandler - called once card has finsihed its animation
		 * @param showContainer - container card displays in, if not specified will use default that was given on ItemGroup setup.
		 */
		public function showAndGetItem(itemID:String, type:String = null, transitionCompleteHandler:Function = null, showContainer:DisplayObjectContainer = null, item:Entity = null):void
		{			
			// NOT IN USE :: Needs more work
			/*if(item && item.has(Collection))
			{
				var collectionId:String = item.get(Collection).id;
				showItem(itemID, null, null, transitionCompleteHandler, showContainer);
				
				//if(shellApi.getManager(CollectionManager)){}
				
				var currentCollection:String = shellApi.getUserField(collectionId, shellApi.island);
				currentCollection = DataUtils.validString(currentCollection) ? currentCollection + "," + itemID : itemID;
				shellApi.setUserField(collectionId, currentCollection, shellApi.island);
			}
			else*/ 
			if( super.shellApi.getItem(itemID, type) )
			{
				showItem(itemID, type, null, transitionCompleteHandler, showContainer );
			}
		}
		
		/**
		 * Shows card spinning into center of screen and moving into hud icon.
		 * Uses ShowItem group to handle card transition &amp; load.
		 * @param itemId - id of card, corresponds to name of card xml file
		 * @param setId - card set ( e.g. custom/limited, store, carrot, virusHunter ), corresponds to name of folder containing card xml file
		 * @param loadHandler - optional, handler called once card is laoded, CardItem is returned with handler call.
		 * @return 
		 */
		public function showItem( itemID:String, setId:String = "", loadHandler:Function = null, transitionCompleteHandler:Function = null, cardContainer:DisplayObjectContainer = null):void
		{
			setId = DataUtils.validString(setId) ? setId: shellApi.island;	// default to current island if directory not specified
			
			if( _cardInTransition )
			{
				var itemObject:Object = new Object();
				itemObject.method = SHOW;
				itemObject.itemId = itemID;
				itemObject.setId = setId;
				itemObject.handler = loadHandler;
				itemObject.cardContainer = cardContainer;
				_cardQueue.push( itemObject);
			}
			else
			{
				_cardInTransition = true;
				super.parent.pause(true, true);
				//super.shellApi.sceneManager.currentScene.pause(true, true);
				this.unpause(true, true);
				
				_showItemGroup.reset();
				
				_showItemGroup.transitionComplete.addOnce(this.cardTransitionComplete);
				if( transitionCompleteHandler != null )
				{
					_showItemGroup.transitionComplete.addOnce(transitionCompleteHandler);
				}
				_showItemGroup.showCard( itemID, setId, loadHandler, cardContainer );
			}
		}
		
		/**
		 * Shows card moving out of hud icon and to an entity in scene.
		 * Uses ShowItem group to handle card transition &amp; load.
		 * @param itemID
		 * @param charID
		 * @param setId
		 * @param loadHandler
		 * @param transitionCompleteHandler
		 */
		public function takeItem( itemID:String, charID:String, setId:String = "", loadHandler:Function = null, transitionCompleteHandler:Function = null ):void
		{
			setId = DataUtils.validString(setId) ? setId: shellApi.island;	// deafult to current island if directory not specified
			
			if( _cardInTransition )
			{
				var itemObject:Object = new Object();
				itemObject.method = TAKE;
				itemObject.itemId = itemID;
				itemObject.setId = setId;
				itemObject.charID = charID;
				itemObject.handler = loadHandler;
				itemObject.transitionCompleteHandler = transitionCompleteHandler;
				_cardQueue.push( itemObject);
			}
			else
			{
				_cardInTransition = true;
				super.parent.pause(true, true);
				//super.shellApi.sceneManager.currentScene.pause(true, true);
				this.unpause(true, true);
				
				_showItemGroup.reset();
				
				var charEntity:Entity = super.parent.getEntityById(charID);
				_showItemGroup.transitionComplete.addOnce(this.cardTransitionComplete);
				if( transitionCompleteHandler != null )
				{
					_showItemGroup.transitionComplete.addOnce(transitionCompleteHandler);
				}
				_showItemGroup.takeItem( itemID, setId, charEntity );
			}
		}
		
		/**
		 * Shows card change.
		 * Uses ShowItem group to handle card transition &amp; load.
		 * @param itemID
		 * @param setId
		 * @param loadHandler
		 * @param transitionCompleteHandler
		 */
		public function refreshItem( itemID:String, setId:String = "", loadHandler:Function = null, transitionCompleteHandler:Function = null ):void
		{
			setId = DataUtils.validString(setId) ? setId: shellApi.island;	// deafult to current island if directory not specified
			
			if( _cardInTransition )
			{
				var itemObject:Object = new Object();
				itemObject.method = REFRESH;
				itemObject.itemId = itemID;
				itemObject.setId = setId;
				itemObject.handler = loadHandler;
				_cardQueue.push( itemObject);
			}
			else
			{
				_cardInTransition = true;
				super.parent.pause(true, true);
				//super.shellApi.sceneManager.currentScene.pause(true, true);
				this.unpause(true, true);
				
				_showItemGroup.reset();
				
				_showItemGroup.transitionComplete.addOnce(this.cardTransitionComplete);
				if( transitionCompleteHandler != null )
				{
					_showItemGroup.transitionComplete.addOnce(transitionCompleteHandler);
				}
				_showItemGroup.refreshItem( itemID, setId );
			}
		}
		
		/**
		 * Handler for when the card is transition is completed
		 */
		private function cardTransitionComplete():void
		{
			_cardInTransition = false;
			
			if( _cardQueue.length > 0 )
			{
				var itemObject:Object = _cardQueue.shift();
				if( itemObject.method == SHOW )
				{
					showItem( itemObject.itemId, itemObject.setId, itemObject.handler, null, itemObject.cardContainer );
				}
				else if( itemObject.method == TAKE )
				{
					takeItem( itemObject.itemId, itemObject.charID, itemObject.setId, itemObject.handler,itemObject.transitionCompleteHandler );
				}
				else if( itemObject.method == REFRESH )
				{
					refreshItem( itemObject.itemId, itemObject.setId, itemObject.handler );
				}
			}
			else
			{
				super.parent.unpause(true, true);
				//super.shellApi.sceneManager.currentScene.unpause(true, true);
			}
		}
		
		private function onEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			addNewItems(event);
		}
		
		private function addNewItems(event:String):void
		{
			if( _allItemData != null )
			{
				for each (var itemData:SceneItemData in _allItemData)
				{
					if(itemData.triggeredByEvent == event)
					{
						if(!super.parent.getEntityById(itemData.id) && !super.shellApi.checkItemEvent(itemData.id))
						{
							addSceneItemByData(itemData, false);
						}
					}
				}
			}
		}
		
		public static const ITEM_PREFIX:String = "item";	// prepended to custom/limited & store card ids as they come in as numbers.
		
		private var _cardInTransition:Boolean = false;
		private var _cardQueue:Vector.<Object>;
		private var _sceneItemCreator:SceneItemCreator;
		private var _overlayContainer:DisplayObjectContainer;
		private var _itemContainer:DisplayObjectContainer;	// container that stores items placed in scene
		private var _showItemGroup:ShowItem;
		private var _itemsLoading:Number = 0;
		private var _itemsLoaded:Signal;
		private var _allItemData:Dictionary;
		public static const GROUP_ID:String = "itemGroup";
		private const SHOW:String = "show";
		private const TAKE:String = "take";
		private const REFRESH:String = "refresh";
	}
}