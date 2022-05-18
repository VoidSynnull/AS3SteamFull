package game.creators.scene
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	
	import game.components.entity.Collection;
	import game.components.entity.Sleep;
	import game.components.hit.Item;
	import game.components.scene.SceneInteraction;
	import game.creators.ui.ToolTipCreator;
	import game.data.item.SceneItemData;
	import game.data.scene.labels.LabelData;
	import game.data.ui.ToolTipType;

	public class SceneItemCreator
	{
		public function create(itemDisplay:DisplayObjectContainer, sceneItemData:SceneItemData, group:Group = null, bitmapItem:Boolean = false, width:Number = NaN, height:Number = NaN):Entity
		{
			var sceneItem : Entity = new Entity();
			var labelData:LabelData = sceneItemData.label;
			var spatial : Spatial = new Spatial();
			spatial.x = sceneItemData.x;
			spatial.y = sceneItemData.y;
			spatial.rotation = sceneItemData.rotation;
			
			if(labelData == null)
			{
				labelData = new LabelData();
				labelData.text = "Examine";
				labelData.type = "exitDown";
			}
			
			sceneItem.add(spatial);
			sceneItem.add(new Sleep());
			var display:Display = new Display();
			var idComponent:Id = new Id();
			idComponent.id = sceneItemData.id;
			sceneItem.add(idComponent);
			
			if(sceneItemData.collection)
			{
				sceneItem.add(new Collection(sceneItemData.collection));
			}
			
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.offsetX = 0;
			sceneInteraction.offsetY = 0;
			
			sceneItem.add(sceneInteraction);

			if(bitmapItem)
			{
				if(isNaN(width))
				{
					width = itemDisplay.width;
				}
				
				if(isNaN(height))
				{
					height = itemDisplay.height;
				}
				
				var itemBitmapData:BitmapData = new BitmapData(width, height, true, 0x000000);
				
				itemBitmapData.draw(itemDisplay);
				
				display.displayObject = new Bitmap(itemBitmapData);
			}
			else
			{
				display.displayObject = itemDisplay;
			}
			
			sceneItem.add(display);
			var itemComp:Item = new Item();
			if(display.displayObject.width / 2 > itemComp.minRangeX) itemComp.minRangeX = display.displayObject.width / 2;			
			if(display.displayObject.height / 2 > itemComp.minRangeY) itemComp.minRangeY = display.displayObject.height / 2;
			sceneItem.add(itemComp);
			
			sceneInteraction.minTargetDelta.x = itemComp.minRangeX;
			sceneInteraction.minTargetDelta.y = itemComp.minRangeY;
			
			InteractionCreator.addToEntity(sceneItem, [InteractionCreator.CLICK]);
			
			if(group != null)
			{
				group.addEntity(sceneItem);
				var interactionBounds:Rectangle = itemDisplay.getBounds(itemDisplay.parent);
				
				if(labelData.offset == null)
				{
					labelData.offset = new Point();
					labelData.offset.x = (interactionBounds.x - itemDisplay.x) + interactionBounds.width * .5;
					labelData.offset.y = (interactionBounds.y - itemDisplay.y) + interactionBounds.height;
				}
			
				ToolTipCreator.addToEntity(sceneItem, ToolTipType.CLICK, labelData.text, labelData.offset);
			}
			
			return(sceneItem);
		}
		
		public function make(entity:Entity, minTargetDelta:Point = null, addClick:Boolean = true):void
		{
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.minTargetDelta = minTargetDelta;
			entity.add(sceneInteraction);
			ToolTipCreator.addToEntity(entity);
			entity.add(new Item());
			
			if(addClick)
			{
				InteractionCreator.addToEntity(entity, [InteractionCreator.CLICK]);
			}
			else
			{
				var display:Display = entity.get(Display);
				
				if(display)
				{
					if(display.displayObject != null)
					{
						display.displayObject.mouseEnabled = false;
						display.displayObject.mouseChildren = false;
					}
				}
			}
		}
	}
}