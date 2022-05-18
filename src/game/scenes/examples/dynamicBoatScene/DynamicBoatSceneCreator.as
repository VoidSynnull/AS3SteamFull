package game.scenes.examples.dynamicBoatScene
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.DisplayGroup;
	import engine.group.Group;
	
	import game.components.entity.Sleep;
	import game.components.hit.BitmapHitArea;
	import game.components.motion.Edge;
	import game.creators.scene.DoorCreator;
	import game.scene.template.CollisionGroup;
	import game.util.BitmapUtils;
	import game.util.EntityUtils;

	public class DynamicBoatSceneCreator
	{
		public function DynamicBoatSceneCreator(container:DisplayObjectContainer)
		{
			_container = container;
		}
		
		public function createAllFromData(elements:Vector.<GridElementData>, group:Group):void
		{
			for each(var element:GridElementData in elements)
			{
				createFromData(element, group);
			}
		}
		
		public function createFromData(data:GridElementData, group:Group = null):Entity
		{
			var entity:Entity = new Entity();			
			var entityGridElement:EntityGridElement = new EntityGridElement();
			entityGridElement.creator = this;
			entityGridElement.data = data;
			
			entity.add(entityGridElement);
			entity.add(new Spatial(data.x, data.y));
			entity.add(new Edge(0, 0, 511, 434));
			var sleep:Sleep = new Sleep();
			sleep.useEdgeForBounds = true;
			entity.add(sleep);
			if(data.id != null) { entity.add(new Id(data.id)); }
			
			if(group != null) { group.addEntity(entity); }
			
			return(entity);
		}
				
		public function show(node:EntityGridElementNode):void
		{
			EntityUtils.loadAndSetToDisplay(_container, node.entityGridElement.data.url, node.entity, DisplayGroup(node.entity.group), elementLoaded, false);
		}
		
		private function elementLoaded(asset:MovieClip, entity:Entity):void
		{
			var entityGridElement:EntityGridElement = entity.get(EntityGridElement);
			var data:GridElementData = entityGridElement.data;
			var spatial:Spatial = entity.get(Spatial);
			
			if(data.bitmap)
			{
				var bitmap:Bitmap = BitmapUtils.createBitmap(asset.art);
				asset.addChildAt(bitmap, asset.getChildIndex(asset.art));
				asset.removeChild(asset.art);
			}
			
			var display:Display = entity.get(Display);
			
			if(data.door != null)
			{
				var doorCreator:DoorCreator = new DoorCreator();
				var doorEntity:Entity = doorCreator.create(asset.door, data.door, null, entity.group);
				var doorSpatial:Spatial = doorEntity.get(Spatial);
				doorSpatial.x += spatial.x;
				doorSpatial.y += spatial.y;
				EntityUtils.addParentChild(doorEntity, entity);
			}
		
			if(asset.hit != null)
			{
				var hitEntity:Entity = entity.group.getEntityById(CollisionGroup.HITAREA_ENTITY_ID);
				var hitArea:BitmapHitArea = hitEntity.get(BitmapHitArea);
				var hitAreaBitmapData:BitmapData = hitArea.bitmapData;
				var hitAreaSpatial:Spatial = hitEntity.get(Spatial);
				var bitmapData:BitmapData = BitmapUtils.createBitmapData(asset.hit, hitAreaSpatial.scale);
				var bounds:Rectangle = asset.hit.getBounds(asset.hit);
				var offsetX:Number = -bounds.left * hitAreaSpatial.scale;
				var offsetY:Number = -bounds.top * hitAreaSpatial.scale;
				var sourceArea:Rectangle;
				var destinationPosition:Point;
				
				if(entityGridElement.hitArea == null)
				{
					sourceArea =  new Rectangle(offsetX, offsetY, asset.hit.width * hitAreaSpatial.scale - offsetX, asset.hit.height * hitAreaSpatial.scale - offsetY);
					destinationPosition = new Point(spatial.x * hitAreaSpatial.scale, spatial.y * hitAreaSpatial.scale);
					var bitmapHitArea:Rectangle = new Rectangle(destinationPosition.x, destinationPosition.y, sourceArea.width, sourceArea.height);
					entityGridElement.hitArea = bitmapHitArea;
				}
				else
				{
					// reuse the position calculations if we have them.
					sourceArea =  new Rectangle(offsetX, offsetY, entityGridElement.hitArea.width, entityGridElement.hitArea.height);
					destinationPosition = new Point(entityGridElement.hitArea.x, entityGridElement.hitArea.y);
				}
				
				// copy the hit area vector into the hit area bitmap data, accouting for scale and offset from 0,0
				hitAreaBitmapData.copyPixels(bitmapData, sourceArea, destinationPosition);
				// remove the original hit movieclip
				asset.removeChild(asset.hit);
				
				// testing for dynamic hits
				if(_showHits)
				{
					var hitBitmap:Bitmap = new Bitmap(hitAreaBitmapData);
					hitBitmap.alpha = .3;
					_container.addChild(hitBitmap);
					_container.mouseEnabled = false;
					_container.mouseChildren = false;
					hitBitmap.x = -hitAreaSpatial.x / hitAreaSpatial.scale;
					hitBitmap.y = -hitAreaSpatial.y / hitAreaSpatial.scale;
					hitBitmap.scaleX = 1 / hitAreaSpatial.scale;
					hitBitmap.scaleY = 1 / hitAreaSpatial.scale;
				}
			}
		}
		
		public function hide(node:EntityGridElementNode):void
		{
			// create a barebones entity for showing later with just the base components needed to get picked up by EntityGridSystem.
			var entity:Entity = new Entity();
			var element:EntityGridElement = node.entityGridElement;
			
			entity.add(new Spatial(node.spatial.x, node.spatial.y));
			
			var sleep:Sleep = new Sleep();
			sleep.useEdgeForBounds = true;
			sleep.sleeping = true;
			entity.add(sleep);
			
			entity.add(new Edge(0, 0, 511, 434));
			entity.add(element);
			if(element.data.id != null) { entity.add(new Id(element.data.id)); }
			node.entity.group.addEntity(entity, true);
			
			var hitEntity:Entity = node.entity.group.getEntityById(CollisionGroup.HITAREA_ENTITY_ID);
			var hitArea:BitmapHitArea = hitEntity.get(BitmapHitArea);
			var hitAreaBitmapData:BitmapData = hitArea.bitmapData;
			// create a 'blank' bitmapData to replace the hit
			var bitmapData:BitmapData = new BitmapData(element.hitArea.width, element.hitArea.height);
			
			hitAreaBitmapData.copyPixels(bitmapData, new Rectangle(0, 0, element.hitArea.width, element.hitArea.height), new Point(element.hitArea.x, element.hitArea.y));
			
			// remove old entity to clear its components, display, etc.
			node.entity.group.removeEntity(node.entity, true);
		}
		
		private var _container:DisplayObjectContainer;
		private var _showHits:Boolean = false;
	}
}