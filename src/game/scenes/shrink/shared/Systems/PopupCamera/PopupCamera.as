package game.scenes.shrink.shared.Systems.PopupCamera
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.motion.FollowTarget;
	import game.util.EntityUtils;
	
	public class PopupCamera extends Component
	{
		public var area:Rectangle;
		public var bounds:Rectangle;
		public var viewPort:Rectangle;
		public var center:Point;
		public var layers:Vector.<Spatial>;
		public var focus:Spatial;
		public var follow:FollowTarget;
		public var group:Group;
		public var container:DisplayObjectContainer;
		public var zoom:Number;
		
		public function PopupCamera(group:Group, container:DisplayObjectContainer, area:Rectangle, viewPort:Rectangle)
		{
			zoom = 1;
			this.group = group;
			this.container = container;
			this.area = area;
			this.viewPort = viewPort;
			center = new Point(viewPort.width / 2, viewPort.height/2);
			bounds = new Rectangle(area.left, area.top, area.width - viewPort.width, area.height - viewPort.height);
			
			this.layers = new Vector.<Spatial>();
			
			var focalEntity:Entity = EntityUtils.createSpatialEntity(group, new Sprite(), container);
			focalEntity.add(new FollowTarget());
			follow = focalEntity.get(FollowTarget);
			focus = focalEntity.get(Spatial);
		}
		
		public function setCameraZoom(zoom:Number):void
		{
			area.left *= zoom;
			area.right *= zoom;
			area.top *= zoom;
			area.bottom *= zoom;
			bounds = new Rectangle(area.left, area.top, area.width - viewPort.width, area.height - viewPort.height);
			
			for(var i:int = 0; i < layers.length; i++)
			{
				layers[i].scale = zoom;
			}
			this.zoom = zoom;
		}
		
		public function setTarget(target:Spatial = null, rate:Number = 1, offSet:Point = null):void
		{
			follow.target = target;
			follow.rate = rate;
			follow.offset = offSet;
		}
		
		public function moveToPoint(point:Point):void
		{
			focus.x = point.x;
			focus.y = point.y;
		}
		
		public function addLayer(layer:DisplayObjectContainer, fitToScreen:Boolean = true):Entity
		{
			var entity:Entity = EntityUtils.createSpatialEntity(group, layer, container);
			var layerSpatial:Spatial = entity.get(Spatial);
			layerSpatial.scale = zoom;
			var scaleDifference:Number = zoom;
			
			if(layer.width * zoom < viewPort.width || layer.height * zoom < viewPort.height)
			{
				if(layer.width >= layer.height)
					scaleDifference = viewPort.height / layer.height;
				else
					scaleDifference = viewPort.width / layer.width;
			}
			
			layers.push(layerSpatial);
			
			if(scaleDifference > zoom && fitToScreen)
				setCameraZoom(scaleDifference);
			
			return entity;
		}
	}
}