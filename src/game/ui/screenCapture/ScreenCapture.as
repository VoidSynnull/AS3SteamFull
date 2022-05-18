package game.ui.screenCapture
{
	import com.adobe.images.PNGEncoder;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	
	import game.components.entity.Children;
	import game.components.motion.Draggable;
	import game.components.motion.Edge;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.systems.dragAndDrop.ValidIds;
	import game.systems.motion.DraggableSystem;
	import game.ui.popup.Popup;
	import game.util.BitmapUtils;
	import game.util.DisplayPositions;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	
	public class ScreenCapture extends Popup
	{
		public var image:DisplayObjectContainer;
		private var screenCap:Entity;
		private var bounds:Rectangle;
		public var cropRectangle:Rectangle;
		private var save:Boolean;
		public var confim:Boolean;
		public var caption:CaptionData;
		
		public function ScreenCapture(container:DisplayObjectContainer = null, image:DisplayObjectContainer = null, bounds:Rectangle = null, save:Boolean = true)
		{
			if(image == null)
				image = container;
			this.image = image;
			this.bounds = bounds;
			this.save = confim = save;
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);
			screenAsset = "screenCapture.swf";
			groupPrefix = "ui/screenCapture/";
			if(bounds == null)
			{
				bounds = new Rectangle(0,0,shellApi.viewportWidth, shellApi.viewportHeight);
			}
			load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			addSystem(new DraggableSystem());
			
			var clip:MovieClip = screen.content;
			clip.mouseEnabled = false;
			screenCap = EntityUtils.createSpatialEntity(this,clip);
			
			var entity:Entity;
			var drag:Draggable;
			var axis:String;
			var x:Boolean;
			var y:Boolean;
			for each (var node:MovieClip in clip)
			{
				entity = EntityUtils.createSpatialEntity(this, node);
				EntityUtils.addParentChild(entity, screenCap);
				entity.add(new ValidIds(node.name.split("_"))).add(new Id(node.name));
				InteractionCreator.addToEntity(entity, ["up","down",InteractionCreator.RELEASE_OUT]);
				
				x = y = false;
				
				axis = null;
				
				if(node.name.indexOf("left") >= 0 || node.name.indexOf("right") >= 0 || node.name == "center")
					x = true;
				if(node.name.indexOf("top") >= 0 || node.name.indexOf("bottom") >= 0 || node.name == "center")
					y = true;
				
				if(x && !y)
					axis = "x";
				if(y && !x)
					axis = "y";
				
				drag = new Draggable(axis);
				drag.dragging.add(updateNodes);
				entity.add(drag).add(new Edge());
				ToolTipCreator.addToEntity(entity);
			}
			//center edge is the size of bounds
			entity = getEntityById("center",screenCap);
			cropRectangle = bounds.clone();
			Edge(entity.get(Edge)).unscaled = new Rectangle(-bounds.width /2, -bounds.height / 2, bounds.width, bounds.height);
			updateNodes(entity);
			
			clip = screen["confirm"];
			layout.pinToEdge(clip, DisplayPositions.BOTTOM_RIGHT,-10,-10);
			trace(screen.x + " " + screen.y);
			
			ButtonCreator.createButtonEntity(clip,this,null,screen);
			clip.addEventListener(MouseEvent.CLICK,captureScreen);
			
			loadCloseButton();
		}
		
		private function updateNodes(entity:Entity):void
		{
			var children:Children = screenCap.get(Children);
			
			var ids:Array = Id(entity.get(Id)).id.split("_");
			
			var target:Spatial = entity.get(Spatial);
			
			var edge:Edge = entity.get(Edge);
			var rect:Rectangle = edge.unscaled;
			
			// making sure you arent dragging tool past bounds
			
			if(target.x + rect.right > bounds.right)
				target.x = bounds.right - rect.right;
			if(target.x + rect.left < bounds.left)
				target.x = bounds.left - rect.left;
			
			if(target.y + rect.top < bounds.top)
				target.y = bounds.top - rect.top;
			if(target.y + rect.bottom > bounds.bottom)
				target.y = bounds.bottom - rect.bottom;
			
			// center moves entire tool
			// can reposition tool by moving top left and bottom right corners
			var spatial:Spatial;
			if(ids[0] == "center")
			{
				spatial = children.getChildByName("top_left").get(Spatial);
				spatial.x = target.x - cropRectangle.width / 2;
				spatial.y = target.y - cropRectangle.height / 2;
				
				spatial = children.getChildByName("bottom_right").get(Spatial);
				spatial.x = target.x + cropRectangle.width / 2;
				spatial.y = target.y + cropRectangle.height / 2;
				
				updateNodes(children.getChildByName("bottom_right"));
				updateNodes(children.getChildByName("top_left"));
				return;
			}
			
			// current node manipulates rectangle to change its dimensions
			// position other nodes that are effected by same side as current node
			for each (var string:String in ids)
			{
				for each (var node:Entity in children.children)
				{
					if(node == entity)
						continue;
					
					spatial = node.get(Spatial);
					
					if(ValidIds(node.get(ValidIds)).isValidId(string))
					{
						if(string == "right" || string == "left")
							spatial.x = target.x;
						if(string == "top" || string == "bottom")
							spatial.y = target.y;
					}
				}
			}
			
			//repositions other nodes to account for changes made to keep tool looking like a proper rectangle
			reAlignRectangle();
			
			//draw rect to highlight what is to be croped out / kept
			
			var clip:MovieClip = EntityUtils.getDisplayObject(screenCap) as MovieClip;
			clip.graphics.clear();
			clip.graphics.beginFill(0, .5);
			clip.graphics.drawRect(0,0,shellApi.viewportWidth, shellApi.viewportHeight);
			clip.graphics.drawRect(cropRectangle.x, cropRectangle.y, cropRectangle.width, cropRectangle.height);
			clip.graphics.endFill()
		}
		
		private function reAlignRectangle(...args):void
		{
			var children:Children = screenCap.get(Children);
			var spatial:Spatial = children.getChildByName("top_left").get(Spatial);
			var target:Spatial = children.getChildByName("bottom_right").get(Spatial);
			
			// resize crop rectangle based off topLeft and bottomRight corners making sure it is not inverted
			cropRectangle.topLeft = new Point(Math.min(spatial.x, target.x), Math.min(spatial.y, target.y));
			cropRectangle.bottomRight = new Point(Math.max(spatial.x, target.x), Math.max(spatial.y, target.y));
			
			//reposition center and change its edge to be the size of new cropRectangle
			var entity:Entity = children.getChildByName("center");
			spatial = entity.get(Spatial);
			Edge(entity.get(Edge)).unscaled = new Rectangle(-Math.abs(cropRectangle.width / 2), -Math.abs(cropRectangle.height / 2), Math.abs(cropRectangle.width), Math.abs(cropRectangle.height));
			
			spatial.x = cropRectangle.left + cropRectangle.width / 2;
			spatial.y = cropRectangle.top + cropRectangle.height / 2;
			
			// reposition sides to be centered based off crop rectangle
			spatial = children.getChildByName("left").get(Spatial);
			target = children.getChildByName("right").get(Spatial);
			
			spatial.y = target.y = cropRectangle.top + cropRectangle.height / 2;
			
			spatial = children.getChildByName("top").get(Spatial);
			target = children.getChildByName("bottom").get(Spatial);
			
			spatial.x = target.x = cropRectangle.left + cropRectangle.width / 2;
		}
		
		private function offsetRectangle():void
		{
			// offset rectangle to be where image is as opposed to where rectangle is
			var offset:Point = DisplayUtils.localToLocal(image, container);
			cropRectangle.x -= offset.x;
			cropRectangle.y -= offset.y;
		}
		// has to be a direct flash event for security purposes
		private function captureScreen(e:MouseEvent):void
		{
			if(!save)
			{
				confim = true;
				close();
				return;
			}
			offsetRectangle();
			//bitmap photo
			
			if(caption != null)
			{
				image.addChild(caption);
				caption.x = cropRectangle.left + cropRectangle.width * caption.alignX;
				caption.y = cropRectangle.top + cropRectangle.height * caption.alignY;
				trace(caption.y);
			}
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(image,1,cropRectangle);
			var byteArray:ByteArray = PNGEncoder.encode(bitmapData);
			
			if(caption != null)
				image.removeChild(caption);
			
			var fileName:String = "photoCrop.png";
			
			var file:FileReference = new FileReference();
			file.save(byteArray,fileName);
			bitmapData.dispose();
			
			//reset it so it doesnt keep getting offset every time you bitmap it
			reAlignRectangle();
		}
	}
}