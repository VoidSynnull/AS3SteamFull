package game.scenes.backlot.postProduction.drawingSystem
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	import org.osflash.signals.Signal;
	
	public class Draw extends Component
	{
		public var penDown:Boolean;
		public var drawing:Boolean;
		public var canvas:MovieClip;
		public var thickness:Number;
		public var color:Number;
		public var offset:Point;
		public var scale:Point;
		public var drawingPoint:Point;
		public var limits:Rectangle;
		public var outSideLimits:Signal;
		public function Draw(canvas:MovieClip = null, thickness:Number = 1, color:Number = 0x000000, offset:Point = null, scale:Point = null, limits:Rectangle = null)
		{
			this.canvas = canvas;
			this.thickness = thickness;
			this.color = color;
			
			this.offset = offset;
			if(this.offset == null)
				this.offset = new Point();
			
			this.scale = scale;
			if(this.scale == null)
				this.scale = new Point(1,1);
			
			this.limits = limits;
			drawingPoint = new Point();
			penDown = false;
			drawing = false;
			outSideLimits = new Signal(Rectangle, Point);
		}
		
		public function erase():void
		{
			penDown = false;
			if(canvas == null)
				return;
			
			canvas.graphics.clear();
		}
	}
}