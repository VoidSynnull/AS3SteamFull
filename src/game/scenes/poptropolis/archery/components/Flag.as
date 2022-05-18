package game.scenes.poptropolis.archery.components 
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class Flag extends Component
	{
		public var wait:Number = 0;
		public var p0:Point;
		public var p1:Point;
		public var p2:Point;
		public var p3:Point;
		public var p4:Point;
		public var p5:Point;
		
		public var p1StartY:Number;
		public var p2StartY:Number;
		public var p3StartY:Number;
		public var p4StartY:Number;
		
		public var p1t:Number;
		public var p2t:Number;
		public var p3t:Number;
		public var p4t:Number;
		
		public var speed:Number;
		public var leftOffset:Number;
		
		public function Flag(zero:Point, one:Point, two:Point, three:Point, four:Point, five:Point)
		{
			p0 = zero;
			p1 = one;
			p2 = two;
			p3 = three;
			p4 = four;
			p5 = five;
			
			p1StartY = p1.y;
			p2StartY = p2.y;
			p3StartY = p3.y;
			p4StartY = p4.y;
			
			p1t = 0;
			p2t = 1;
			p3t = 0;
			p4t = 0;
			
			speed = 0.05;
			leftOffset = 0;
		}
	}
}