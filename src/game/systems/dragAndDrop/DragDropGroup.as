package game.systems.dragAndDrop
{
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.entity.Parent;
	import game.components.motion.Draggable;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.systems.motion.DraggableSystem;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	import org.osflash.signals.Signal;
	
	public class DragDropGroup extends Group
	{
		public var dragging:Boolean;
		public var drags:int;
		public var drops:int;
		public var dragsAtOrigin:Boolean;
		public var dropsRefundable:Boolean;
		public var dragName:String;
		public var dropName:String;
		public var dragList:Vector.<Entity>;
		public var dropList:Vector.<Entity>;
		public var dispatchForInvalidDrops:Boolean = false;
		
		public function DragDropGroup(container:DisplayObjectContainer)
		{			
			super();
			this.id = GROUP_ID;
			this.container = container;
			placedEntity = new Signal(Entity, Entity, Boolean);
			pickedUpEntity = new Signal(Entity);
		}
		
		public function setUpDragAndDrops(onDragPlaced:Function = null):void
		{
			baseContainer = EntityUtils.createSpatialEntity(parent, container);
			
			dragList = new Vector.<Entity>();
			dropList = new Vector.<Entity>();
			
			parent.addSystem(new DraggableSystem());
			
			if(onDragPlaced != null)
				placedEntity.add(onDragPlaced);
			for each(var clip:DisplayObject in container)
			{
				if(clip.name.indexOf(dropName) == 0)
					setUpDrop(parent,clip as MovieClip,container);
				if(clip.name.indexOf(dragName) == 0)
					setUpDrag(parent,clip as MovieClip,container);
			}
			//making sure drags are on top
			if(dropList.length == 0)
				return;
			for( var i:int = 0; i < dragList.length; i++)
			{
				Display(dragList[i].get(Display)).moveToFront();
			}
		}
		// dont add drag and drop to the same entity
		
		override public function destroy():void
		{
			var children:Children
			for each(var entity:Entity in dropList)
			{
				children = entity.get(Children);
				while(children.children.length > 0)
				{
					parent.removeEntity(children.children.pop());
				}
				parent.removeEntity(entity);
			}
			for each(entity in dragList)
			{
				parent.removeEntity(entity);
			}
			placedEntity.removeAll();
			placedEntity = null;
			pickedUpEntity.removeAll();
			pickedUpEntity = null;
			super.destroy();
		}
		
		public function configDragAndDrops(dragNames:String = "drag", dropNames:String = "drop", dragsAtOrigin:Boolean = true, dropsRefundable:Boolean = false, drags:int = 1, drops:int = 1):void
		{
			this.dragName = dragNames;
			this.dropName = dropNames;
			this.drops = drops;
			this.dragsAtOrigin = dragsAtOrigin;
			this.dropsRefundable = dropsRefundable;
			this.drags = drags;
			this.drops = drops;
		}
		
		public function setUpDrop(group:Group, clip:MovieClip, container:DisplayObjectContainer):Entity
		{
			var point:Point = DisplayUtils.localToLocal(clip, container);
			clip.x = point.x;
			clip.y = point.y;
			
			var ids:Array = clip.name.substr(dropName.length).split("$");//makes a list of everything that can be dragged into it
			var string:String;
			for(var i:int = 0; i < ids.length; i++)
			{
				string = ids[i];
				ids[i] = dragName + string;
			}
			
			var entity:Entity = EntityUtils.createSpatialEntity(group, clip, container);
			addDropToEntity(entity, ids,dropsRefundable, Math.max(ids.length, drops));
			entity.add(new Id(clip.name));
			
			dropList.push(entity);
			
			return entity;
		}
		
		public function setUpDrag(group:Group,clip:MovieClip,container:DisplayObjectContainer):Entity
		{
			var point:Point;
			
			if(dragsAtOrigin)
				point = DisplayUtils.localToLocal(clip, container);
			else
				point = new RectangleZone(clip.width / 2,clip.height / 2,shellApi.viewportWidth - clip.width, shellApi.viewportHeight - clip.height).getLocation();
			
			clip.x = point.x;
			clip.y = point.y;
			
			var entity:Entity = EntityUtils.createSpatialEntity(group, clip, container);
			if(clip.totalFrames > 1)
			{
				TimelineUtils.convertClip(clip, this, entity, null, false);
			}
			addDragToEntity(entity,dragsAtOrigin,clip.name,drags == 0? 0:Math.max(drags, clip.totalFrames));
			entity.add(new Id(clip.name));
			
			dragList.push(entity);
			
			return entity;
		}
		
		public function addDragToEntity(entity:Entity, atOrigin:Boolean = true, id:String = null, dragPool:Number = 1, dragRate:int = 1, dragDisplay:DisplayObjectContainer = null):void
		{
			// in the case that the asset you are dragging is not the same asset you click on;
			if(dragDisplay == null)// but will default to own display
				dragDisplay = EntityUtils.getDisplayObject(entity);
			
			var origin:Point;
			if(atOrigin)
			{
				var spatial:Spatial = entity.get(Spatial);
				origin = new Point(spatial.x, spatial.y);
			}
			
			if(entity.get(Children) == null)
				entity.add(new Children());
			
			entity.add(new Drag(dragDisplay, id, origin, dragRate))
				.add(new Capacity(dragPool,true)).add(new Draggable());
			
			addInteractionToEntity(entity);
			addDragInteraction(entity);
		}
		
		public function addDropToEntity(entity:Entity, ids:Array = null, refundable:Boolean = true, dropCapacity:int = 1):void
		{
			var interaction:Interaction = addInteractionToEntity(entity);
			interaction.down.add(grabEntity);
			
			if(entity.get(Children) == null)
				entity.add(new Children());
			
			entity.add(new Drop(refundable)).add(new ValidIds(ids))
				.add(new Capacity(dropCapacity));
		}
		
		public function lockDrags(lock:Boolean = true):void
		{
			for(var i:int = 0; i < dragList.length; i++)
			{
				lockDrag(dragList[i], lock);
			}
		}
		
		private function lockDrag(drag:Entity, lock:Boolean):void
		{
			if(lock)
				ToolTipCreator.removeFromEntity(drag);
			else
				ToolTipCreator.addToEntity(drag);
			Interaction(drag.get(Interaction)).lock = lock;
		}
		
		public function resetDrops(instant:Boolean = true):void
		{
			for(var i:int = 0; i < dropList.length; i++)
			{
				resetDrop(dropList[i]);
			}
		}
		
		public function resetDrop(entity:Entity):void
		{
			var children:Children = entity.get(Children);
			if(children.children.length == 0)
			{
				return;
			}
			Capacity(entity.get(Capacity)).remove(1);
			var child:Entity = children.children.pop();
			EntityUtils.visible(child);
			Drag(child.get(Drag)).enabled = true;
			Capacity(child.get(Capacity)).add(1);
			child.add(new Draggable());
			ToolTipCreator.addToEntity(child);
			setContainer(child, baseContainer);
			returnToOrigin(child, true);
			placedEntity.addOnce(Command.create(returnedEntityToOrigin, entity));
		}
		
		private function returnedEntityToOrigin(drag:Entity, drop:Entity, valid:Boolean, currentDrop:Entity):void
		{
			resetDrop(currentDrop);
		}
		
		private function grabEntity(entity:Entity):void
		{
			var children:Children = entity.get(Children);
			if(children.children.length == 0 || !Drop(entity.get(Drop)).refundable)
				return;
			
			Capacity(entity.get(Capacity)).remove(1);
			var child:Entity = children.children.pop();
			EntityUtils.visible(child);
			Drag(child.get(Drag)).enabled = true;
			Capacity(child.get(Capacity)).add(1);
			dragEntity(child);
			//draggable gets messed up when setContainer drastically changes drags position
			var point:Point = DisplayUtils.mouseXY(Display(entity.get(Display)).displayObject);
			var draggable:Draggable = child.get(Draggable);
			draggable.offsetX = point.x;
			draggable.offsetY = point.y;
		}
		
		private function dragEntity(entity:Entity):void
		{
			var drag:Drag = entity.get(Drag);
			var capacity:Capacity = entity.get(Capacity);
			
			if(!drag.enabled || capacity.empty || dragging)
				return;
			
			capacity.remove(1);
			
			if(!capacity.empty && entity.get(Parent) == null)
				entity = duplicateDragEntity(entity);
			else
			{
				addRemoveDropInteractions(entity);
				var clip:MovieClip = EntityUtils.getDisplayObject(entity) as MovieClip;
				if(clip != null)
					clip.gotoAndStop(capacity.capacity);
			}
			
			// want to make sure drag is on target and doesnt get thrown off when you move mouse quickly while picking it up
			var display:DisplayObjectContainer = EntityUtils.getDisplayObject(entity);
			var bounds:Rectangle = display.getBounds(display);
			var draggable:Draggable = entity.get(Draggable);
			///*
			if(draggable.offsetX < -bounds.right)
				draggable.offsetX = -bounds.right / 2;
			if(draggable.offsetX > -bounds.left)
				draggable.offsetX = -bounds.left / 2;
			if(draggable.offsetY < -bounds.bottom)
				draggable.offsetY = -bounds.bottom / 2;
			if(draggable.offsetY > -bounds.top)
				draggable.offsetY = -bounds.top / 2;
			//*/
			setContainer(entity, baseContainer);
			
			dragging = true;
			
			pickedUpEntity.dispatch(entity);
		}
		
		private function duplicateDragEntity(entity:Entity):Entity
		{
			var drag:Drag = entity.get(Drag);
			var capacity:Capacity = entity.get(Capacity);
			var parent:Parent = new Parent(entity);
			var parentDrag:Draggable = entity.get(Draggable);
			var spatial:Spatial = entity.get(Spatial);
			parentDrag._active = false;
			// in case drag gets moved in the frame it was clicked
			spatial.x = drag.origin.x;
			spatial.y = drag.origin.y;
			
			var clip:DisplayObjectContainer = drag.asset;
			
			var frames:int = MovieClip(clip).totalFrames;
			if(frames > 1)
			{
				var frame:int = int(Math.random() * frames);
				if(!capacity.infinte)
					frame = MovieClip(clip).totalFrames - capacity.count;
				trace(frame + " " + capacity.count);
				MovieClip(clip).gotoAndStop(frame + 1);
				Timeline(entity.get(Timeline)).gotoAndStop(frame + 1);
			}
			
			var sprite:Sprite = BitmapUtils.createBitmapSprite(clip);
			spatial = shellApi.inputEntity.get(Spatial);
			sprite.x = spatial.x;
			sprite.y = spatial.y;
			
			entity = EntityUtils.createSpatialEntity(this.parent, sprite);
			
			var draggable:Draggable = new Draggable();
			draggable.offsetX = parentDrag.offsetX;
			draggable.offsetY = parentDrag.offsetY;
			
			entity.add(new Drag(drag.asset, drag.id, drag.origin, drag.rate))
				.add(new Capacity()).add(parent).add(draggable);
			
			addInteractionToEntity(entity);
			addRemoveDropInteractions(entity);
			addDragInteraction(entity);
			
			var children:Children = parent.parent.get(Children);
			children.children.push(entity);
			
			SceneUtil.delay(this,.02,draggable.onDrag);
						
			return entity;
		}
		
		private function addInteractionToEntity(entity):Interaction
		{
			return InteractionCreator.addToEntity(entity, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
		}
		
		private function addDragInteraction(entity:Entity):void
		{
			ToolTipCreator.addToEntity(entity);
			var drag:Draggable = entity.get(Draggable);
			drag.drag.add(dragEntity);
		}
		
		private function addRemoveDropInteractions(entity:Entity, add:Boolean = true):void
		{
			var drag:Draggable = entity.get(Draggable);
			trace("add Drop interaction: " + add);
			if(add)
			{
				drag.drop.add(dropEntity);
			}
			else
			{
				drag.drop.remove(dropEntity);
			}
		}
		
		private function dropEntity(entity:Entity):void
		{
			trace("dropEntity");
			addRemoveDropInteractions(entity, false);
			
			var spatial:Spatial = shellApi.inputEntity.get(Spatial);
			var mousePoint:Point = new Point((spatial.x - container.x) / container.scaleX , (spatial.y - container.y) / container.scaleY);
			//trace(mousePoint);
			if(parent is Scene)
			{
				mousePoint = mousePoint.add(shellApi.camera.camera.viewport.topLeft);
			}
			var drag:Drag = entity.get(Drag);
			drag.enabled = false;
			
			var dropNodes:NodeList = systemManager.getNodeList(DropNode);
			var rect:Rectangle;
			var valid:Boolean = true;
			var inDropZone:Boolean = false;
			
			for(var node:DropNode = dropNodes.head; node; node = node.next)
			{
				if(node.edge != null)
					rect = node.edge.rectangle;
				else
					rect = EntityUtils.getDisplayObject(node.entity).getRect(node.display.displayObject.parent);
				
				if(rect.contains(mousePoint.x, mousePoint.y) && node.drop.enabled)
				{
					inDropZone = true;
					if(node.validIds != null && node.drop.rejectInvalidIds)
						valid = node.validIds.isValidId(drag.id);
					
					if(valid && !node.capacity.full)// if droped in a valid location
					{
						var point:Point = node.drop.dropZone.getLocation();
						if(!node.drop.refundable)
						{
							ToolTipCreator.removeFromEntity(entity);
							entity.remove(Draggable);
						}
						node.children.children.push(entity);
						if(PlatformUtils.isMobileOS)
							setDragToDrop(entity, node.entity);
						else
							TweenUtils.entityTo(entity, Spatial, .5, {x:node.spatial.x + point.x, y:node.spatial.y + point.y, ease:Linear.easeNone, onComplete:Command.create(droppedEntity, entity, node.entity, true, true)});
						return;// move to drop location
					}
				}
			}
			
			returnToOrigin(entity, inDropZone,PlatformUtils.isMobileOS);
		}
		
		public function returnToOrigin(entity:Entity, valid:Boolean, snap:Boolean = false):void
		{
			var drag:Drag = entity.get(Drag);
			if(drag.origin != null)
			{
				if(snap)
				{
					var spatial:Spatial = entity.get(Spatial);
					spatial.x = drag.origin.x;
					spatial.y = drag.origin.y;
					droppedEntity(entity, entity, valid,false);
				}
				else
					TweenUtils.entityTo(entity, Spatial, .5, {x:drag.origin.x, y:drag.origin.y, ease:Linear.easeNone, onComplete:Command.create(droppedEntity, entity, entity, valid, false)});
			}
			else
				droppedEntity(entity, entity, valid, false);
		}
		
		public function setDragToDrop(drag:Entity, drop:Entity):void
		{
			var displayObject:DisplayObject = EntityUtils.getDisplayObject(drag);
			var dragSpatial:Spatial = drag.get(Spatial);
			var dropSpatial:Spatial = drop.get(Spatial);
			dragSpatial.x = displayObject.x = dropSpatial.x;
			dragSpatial.y = displayObject.y = dropSpatial.y;
			droppedEntity(drag, drop, true, true);
		}
		
		private function droppedEntity(entity:Entity, destination:Entity, validDrop:Boolean, correctDrop:Boolean):void
		{
			var capacity:Capacity = destination.get(Capacity);
			// moving to drop
			if(destination.get(Drop))
			{
				var drop:Drop = destination.get(Drop);
				if(drop.hideContents)
				{
					Spatial(entity.get(Spatial)).scale = .01;
				}
				EntityUtils.visible(entity, !drop.hideContents);
			}
			// returning to origin 
			if(destination.get(Drag))
			{
				var drag:Drag = entity.get(Drag);
				drag.enabled = true;
				if(drag.origin && entity.get(Parent))
				{
					var parentEntity:Entity = Parent(entity.get(Parent)).parent;
					var children:Children = parentEntity.get(Children);
					var index:int = children.children.indexOf(entity);
					children.children.splice(index, 1);
					parent.removeEntity(entity);
					entity = destination = parentEntity;
					capacity = entity.get(Capacity);
					var clip:DisplayObjectContainer = drag.asset;
					var frames:int = MovieClip(clip).totalFrames;
					if(frames > 1)
					{
						var frame:int = int(Math.random() * frames);
						if(!capacity.infinte)
							frame = MovieClip(clip).totalFrames - capacity.count;
						MovieClip(clip).gotoAndStop(frame);
						Timeline(entity.get(Timeline)).gotoAndStop(frame);
					}
				}
			}
			
			capacity.add(1);
			
			setContainer(entity, destination);
			
			dragging = false;
			
			if(validDrop || dispatchForInvalidDrops)
				placedEntity.dispatch(entity, destination, correctDrop);
		}
		
		private function setContainer(entity:Entity, destination:Entity):void
		{
			if(entity == destination)
				return;
			
			var entityDisplay:Display = entity.get(Display);
			var destinationDisplay:Display = destination.get(Display);
			
			var zone:Point = new Point();
			var drop:Drop = destination.get(Drop);
			if(drop)
				zone = drop.dropZone.getLocation();
			
			var point:Point = DisplayUtils.localToLocalPoint(zone,entityDisplay.displayObject, destinationDisplay.displayObject);
			var spatial:Spatial = entity.get(Spatial);
			spatial.x = point.x;
			spatial.y = point.y;
			entityDisplay.setContainer(destinationDisplay.displayObject);
		}
		
		public function get allDropsSatisfied():Boolean
		{
			for each(var entity:Entity in dropList)
			{
				var capacity:Capacity = entity.get(Capacity); 
				if(!capacity.full)
					return false;
			}
			return true;
		}
		
		public static const GROUP_ID:String = "dragDropGroup";
		
		public var container:DisplayObjectContainer;
		public var baseContainer:Entity;
		public var placedEntity:Signal;
		public var pickedUpEntity:Signal;
	}
}