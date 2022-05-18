package game.components.render
{
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class DynamicWire extends Component
	{		
		public var startPoint:Point;
		public var endPoint:Point;
		public var wireSprite:Sprite;
		public var previousStart:Point;
		public var previousEnd:Point;
		
		public var droop:Number;
		public var wireLength:Number;
		public var wireColor:uint;
		public var outlineColor:uint;
		public var wireThickness:Number;
		public var outlineThickness:Number;
		public var active:Boolean;
		
		public function DynamicWire(wireLength:Number = 0, wireColor:uint = 0xFFFFFF, outlineColor:uint = 0, wireThickness:Number = 10, outlineThickness:Number = 2, droop:Number = 0)
		{
			this.wireLength = wireLength;
			this.droop = droop;
			this.wireColor = wireColor;
			this.outlineColor = outlineColor;
			this.wireThickness = wireThickness;
			this.outlineThickness = wireThickness + outlineThickness * 2;
			this.active = true;
			
			startPoint = new Point();
			endPoint = new Point();			
			previousEnd = new Point();
			previousStart = new Point();			
			wireSprite = new Sprite();
		}
	}
}
