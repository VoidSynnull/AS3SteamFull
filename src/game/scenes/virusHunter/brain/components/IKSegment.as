package game.scenes.virusHunter.brain.components
{
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	public class IKSegment
	{
		public function IKSegment($display:DisplayObject, $segWidth:Number)
		{
			display = $display;
			segWidth = $segWidth;
			
			origPoint = new Point(display.x, display.y);
			origRotation = display.rotation;
		}
		
		public function getPin():Point
		{
			var angle:Number = display.rotation * Math.PI / 180;
			var xPos:Number = display.x + Math.cos(angle) * segWidth;
			var yPos:Number = display.y + Math.sin(angle) * segWidth;
			
			return new Point(xPos, yPos);
		}
		
		public var display:DisplayObject;
		public var segWidth:Number;
		public var segHeight:Number;
		
		public var origPoint:Point;
		public var origRotation:Number;
	}
}