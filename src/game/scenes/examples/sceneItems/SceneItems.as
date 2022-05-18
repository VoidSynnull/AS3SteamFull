package game.scenes.examples.sceneItems
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.creators.scene.SceneItemCreator;
	import game.nodes.hit.ItemHitNode;
	import game.scene.template.ItemGroup;
	import game.scene.template.PlatformerGameScene;
	import game.systems.hit.ItemHitSystem;
	
	public class SceneItems extends PlatformerGameScene
	{
		public function SceneItems()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/sceneItems/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			var itemHitSystem:ItemHitSystem = super.getSystem(ItemHitSystem) as ItemHitSystem;
			// we are handling gotItem events on our own, so disconnect the signal to prevent default behavior
			itemHitSystem.gotItem.removeAll();
			// wire the gotItem signal to our own handler.
			itemHitSystem.gotItem.add(handleGotItem);
			
			// boxes are setup in items.xml like standard items.  The difference is that they do not have
			//   a corresponding card so their 'gotItem' is handled in scene, and an event is triggered instead of an
			//   item being added to the inventory.  The scene will use the event to 'remember' which ones have
			//   been picked up.
			removePickedUpBoxes();
			
			// ball items exist in the hit container (not in xml).  They are added manually, and all reappear when you reload the scene.
			//   This type of functionality would work well for a 'collection' minigame.
			addBalls(super.hitContainer);
		}
		
		public function handleGotItem(item:Entity):void
		{
			var dialog:Dialog = super.shellApi.player.get(Dialog);
			var itemGroup:ItemGroup = super.getGroupById(ItemGroup.GROUP_ID, this) as ItemGroup;
			var itemID:String = item.get(Id).id;
			
			if(itemID.indexOf("box") > -1)
			{
				// box's use the standard item hits to get picked up, but do not have a corresponding card.
				//   you can use events to remember which ones have been picked up.
				super.shellApi.completeEvent("gotBox_" + itemID);
				
				dialog.say("I found " + itemID);
			
				/**
				 * 	// if you wanted to show the SAME item card for all boxes you could handle it like this:
				    if(!super.shellApi.checkItem("box"))
					{
						itemGroup.showAndGetItem("box");
					}
					else
					{
						itemGroup.showItem("box");
					}
				 */
				
			}
			else if(itemID.indexOf("ball") > -1)
			{
				var dialogString:String;
				
				// for balls we don't bother saving any events to remember which ones we've picked up.  This will
				//   make them all available to find again when the scene next loads.
				_remainingBalls--;
				
				if(_remainingBalls == 0)
				{
					dialogString = "Found em all!";
				}
				else if(_remainingBalls == 1)
				{
					dialogString = "One left!";
				}
				else
				{
					dialogString = "There are " + _remainingBalls + " remaining";
				}
				
				dialog.say(dialogString);
			}
			else
			{
				// if this isn't a special case item, get it and show it like normal.
				itemGroup.showAndGetItem(itemID);
			}
		}
		
		public function removePickedUpBoxes():void
		{			
			var itemNodes:NodeList = super.systemManager.getNodeList(ItemHitNode);
			var event:String;
			
			for( var node : ItemHitNode = itemNodes.head; node; node = node.next )
			{
				event = "gotBox_" + node.id.id;
				// if this box has been found, remove it.
				if(super.shellApi.checkEvent(event))
				{
					super.removeEntity(node.entity, true);
				}
			}
		}
		
		public function addBalls(container:DisplayObjectContainer):void
		{			
			var total:Number = container.numChildren;
			var clip:DisplayObjectContainer;
			var ball:Entity;
			var display:Display;
			var sceneCreator:SceneItemCreator = new SceneItemCreator();

			for (var n:Number = total - 1; n >= 0; n--)
			{
				clip = container.getChildAt(n) as DisplayObjectContainer;
				
				if (clip != null)
				{
					if(clip.name.indexOf("ball") > -1)
					{
						ball = new Entity();
						ball.add(new Spatial());
						ball.add(new Sleep());
						display = new Display(clip);
						display.isStatic = true;
						ball.add(display);
						ball.add(new Id(clip.name));
						clip.mouseEnabled = false;
						clip.mouseChildren = false;
						super.addEntity(ball);
						sceneCreator.make(ball, new Point(25, 100));
					}
				}
			}
		}
		
		private var _remainingBalls:Number = 5;
	}
}