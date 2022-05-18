// only used by CollectionGame.as
package game.scene.template.ads.shared
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineClip;
	import game.creators.scene.SceneItemCreator;
	import game.scene.template.ads.CollectionGame;
	import game.systems.SystemPriorities;
	import game.systems.hit.ItemHitSystem;
	import game.util.AudioUtils;
	import game.util.DataUtils;
	
	public class ItemManager
	{
		public function ItemManager(scene:Group, itemName:String, game:CollectionGame, hud:MovieClip = null, randomCount:Number = 0, collectAnimation:Entity=null)
		{
			_scene = scene;
			_itemName = itemName;
			_collectionGame = game;
			_HUD = hud;
			_randomCount = randomCount;
			_collectAnimation = collectAnimation;
		}
		
		public function setItemName(name:String):void{ 	_itemName = name; }
		
		public function addItems(container:DisplayObjectContainer, firstTime:Boolean = true):void
		{			
			var total:Number = container.numChildren;
			var clip:DisplayObjectContainer;
			var item:Entity;
			var display:Display;
			var sceneCreator:SceneItemCreator = new SceneItemCreator();
			
			items = null;
			
			if (firstTime)
			{
				// get list of items
				_collectibles = [];
				shortList = [];
				_lowestDepth = 9999;
				for (var n:Number = total - 1; n >= 0; n--)
				{
					clip = container.getChildAt(n) as DisplayObjectContainer;
					if (clip != null)
					{
						if(clip.name.indexOf("collect") > -1)
						{
							var index:int = container.getChildIndex(clip);
							if (index < _lowestDepth)
								_lowestDepth = index;
							_collectibles.push(clip);
							shortList.push(clip);
						}
					}
				}
			}
			// if not first time, then create new shortlist
			else
			{
				shortList = _collectibles.concat();
			}
			total = _collectibles.length;
			
			// update HUD so all items are cleared
			if(_HUD != null)
			{
				for(var i:Number = 1; i<= total;i++)
				{
					var hudclip:MovieClip = _HUD.getChildByName("item"+i) as MovieClip;
					if (hudclip != null)
						hudclip.gotoAndStop(1);
				}
			}
			
			// random processing
			if (_randomCount != 0)
			{
				// get start hudx and spacing
				if ((firstTime) && (_HUD != null))
				{
					hudclip = MovieClip(_HUD.getChildByName("item1"));
					_startX = hudclip.x;
					hudclip = MovieClip(_HUD.getChildByName("item2"));
					_spacingX = hudclip.x - _startX;
				}
				
				// get number to trim
				var trim:int = shortList.length - _randomCount;
				while (trim != 0)
				{
					var random:int = Math.floor(Math.random()*shortList.length);
					clip = shortList[random];
					var itemNumber:String = getItemNumber(clip.name);
					// hide in scene
					clip.visible = false;
					// hide in HUD
					if (_HUD != null)
					{
						hudclip = MovieClip(_HUD.getChildByName("item" + itemNumber));
						hudclip.visible = false;
					}
					// remove from array
					shortList.splice(random, 1);
					trim--;
				}
			}
			_totalItems = shortList.length;
			
			for (var c:Number = 0; c != _totalItems; c++)
			{
				clip = shortList[c];
				MovieClip(clip).baseScale = clip.scaleX;
				MovieClip(clip).counter = 0;
				
				// if removed from container then add again at lowest index
				// this does get messed up after a few games
				if (container.getChildByName(clip.name) == null)
					container.addChildAt(clip, _lowestDepth);
				
				item = new Entity();
				item.add(new Spatial());
				item.add(new Sleep());
				display = new Display(clip);
				display.isStatic = true;
				item.add(display);
				item.add(new Id(clip.name));
				clip.mouseEnabled = false;
				clip.mouseChildren = false;
				_scene.addEntity(item);
				sceneCreator.make(item, new Point(25, 100), false);
				
				// if random count and has hud, position hud item
				if ((_randomCount != 0) && (_HUD != null))
				{
					itemNumber = getItemNumber(clip.name);
					hudclip = MovieClip(_HUD.getChildByName("item" + itemNumber));
					hudclip.x = _startX + c * _spacingX;
					hudclip.visible = true;
				}
			}
			if (firstTime)
			{
				var itemHitSystem:ItemHitSystem = new ItemHitSystem();
				_scene.addSystem(itemHitSystem, SystemPriorities.resolveCollisions);
				itemHitSystem.gotItem.add(handleGotItem);
				
				// reset counter text
				if ((_HUD != null) && (_HUD.counter != null))
				{
					_HUD.counter.text = "0";
					//_HUD.counter.text = "0/" + _totalItems;
				}
			}
		}
		
		// to cause items to animate
		public function animateItems(style:String):void
		{
			_animateItems = style;
			_HUD.addEventListener(Event.ENTER_FRAME, fnAnimate);
		}
		
		// when items animate
		private function fnAnimate(event:Event):void
		{
			for (var c:Number = 0; c != _totalItems; c++)
			{
				var clip:MovieClip = shortList[c];
				if (clip.visible)
				{
					clip.counter++;
					switch (_animateItems)
					{
						case "quiver":
							var expand:Number = Math.cos(clip.counter/3);
							clip.scaleX = clip.baseScale * (0.95 + 0.05 * expand);
							clip.scaleY = clip.baseScale * (0.95 - 0.05 * expand);
							break;
					}
				}
			}
		}
		
		public function handleGotItem(item:Entity):void
		{
			var dialog:Dialog = _scene.shellApi.player.get(Dialog);
			var itemID:String = item.get(Id).id;
			
			if(_collectAnimation != null)
			{
				_collectAnimation.get( TimelineClip ).mc.x = _scene.shellApi.player.get(Spatial).x;
				_collectAnimation.get( TimelineClip ).mc.y = _scene.shellApi.player.get(Spatial).y;
				var timeline:Timeline = _collectAnimation.get(Timeline);
				timeline.gotoAndPlay("playAnimation");
			}
			if(items == null)
			{
				items = new Array();
			}
			
			items.push(itemID);
			if(_HUD != null)
			{
				var itemNumber:String = getItemNumber(itemID);
				var hudclip:MovieClip = _HUD.getChildByName("item"+itemNumber) as MovieClip;
				if (hudclip != null)
					hudclip.gotoAndStop(2);
			}
			
			var itemsRemaining:Number = _totalItems - items.length;
			var soundToPlay:String;
			if(DataUtils.validString(_collectionGame._collectSound)) {
				soundToPlay = _collectionGame._collectSound;
			}
			else {
				var itemSound:String = "effects/points_ping_0";
				var pingNumber:uint = 2; //1,2,3,4 for the differnt pings
				var pingynessArray:Array = ["d.mp3","c.mp3","b.mp3","a.mp3","e.mp3"];
				
				var pingyness:int = itemsRemaining / 2;
				if(itemsRemaining == 0 && pingNumber == 4)
					pingyness = 4;
				if(pingNumber < 4 && itemsRemaining > 0 && pingyness < 3)
					pingyness++;
				if (pingyness > 4)
					pingyness = 0;
				
				soundToPlay = itemSound + pingNumber + pingynessArray[pingyness];
			}
			
			AudioUtils.play(_scene,soundToPlay);
			
			if(items.length < _totalItems)
			{
				var itemText:String = " ";
				if(_itemName != "0")
				{
					itemText += _itemName;
					if(items.length != _totalItems - 1)
					{
						itemText += "s";
					}
				}
				
				dialog.say(itemsRemaining + " more" + itemText + " to find!");
				if ((_HUD != null) && (_HUD.counter != null))
				{
					_HUD.counter.text = String(_totalItems - itemsRemaining);
					//_HUD.counter.text = String(_totalItems - itemsRemaining) + "/" + _totalItems;
				}
			}
			else
			{
				_collectionGame.gotAllItems();
			}
		}
		
		private function getItemNumber(name:String):String
		{
			var itemNumber:String = name.substr(7,2);
			var itemSuffix:String = itemNumber.substr(itemNumber.length-1,itemNumber.length)
			if(itemSuffix == "_")
				itemNumber = itemNumber.slice(0,itemNumber.length-1);
			return itemNumber;
		}
		
		private var _scene:Group;
		private var _totalItems:int = 0;
		private var _itemName:String;
		private var _collectionGame:CollectionGame;
		private var items:Array;
		private var shortList:Array;
		private var _HUD:MovieClip;
		private var _collectibles:Array;
		private var _lowestDepth:int;
		private var _randomCount:Number;
		private var _startX:Number;
		private var _spacingX:Number;
		private var _animateItems:String;
		private var _collectAnimation:Entity;
	}
}