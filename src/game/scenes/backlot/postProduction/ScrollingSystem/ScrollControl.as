package game.scenes.backlot.postProduction.ScrollingSystem
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	public class ScrollControl extends Component
	{
		public var scrollingObjects:Vector.<Entity>;
		public var scrollSpeed:Number;
		public var swapXandY:Boolean;
		public var centerEntity:Entity;
		public var scrolling:Boolean;
		
		public function ScrollControl(scrollingObjects:Vector.<Entity> = null, scrollSpeed:Number = 100, swapXandY:Boolean = false)
		{
			this.scrollingObjects = scrollingObjects;
			
			if(this.scrollingObjects == null)
				this.scrollingObjects = new Vector.<Entity>();
			this.scrollSpeed = scrollSpeed;
			
			this.swapXandY = swapXandY;
			scrolling = false;
		}
		
		public function centerizeScrollingObjects():void
		{
			scrolling = false;
			
			var rect:Rectangle = Scroll(scrollingObjects[0].get(Scroll)).bounds;
			var center:Point = new Point(rect.x + rect.width / 2, rect.y + rect.height / 2);
			
			var closestDistance:Number;
			var differrence:Point;
			
			if(rect.width > rect.height)
				closestDistance = rect.width;
			else
				closestDistance = rect.height;
			
			for each(var entity:Entity in scrollingObjects)
			{	
				var pos:Point = new Point(entity.get(Spatial).x, entity.get(Spatial).y);
				var distance:Number = Point.distance(pos, center);
				
				if(distance < closestDistance)
				{
					centerEntity = entity;
					closestDistance = distance;
					differrence = new Point(pos.x - center.x, pos.y - center.y);
				}
			}
			
			for each(entity in scrollingObjects)
			{
				var scroll: Scroll = entity.get(Scroll);
				var target:Point = new Point(entity.get(Spatial).x - differrence.x, entity.get(Spatial).y - differrence.y);
				
				var tween:Tween = new Tween();
				tween.to(entity.get(Spatial), 1, { x: target.x , y: target.y });
				entity.add(tween);
				scroll.speed = new Point();
			}
		}
	}
}