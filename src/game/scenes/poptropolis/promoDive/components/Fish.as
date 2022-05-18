package game.scenes.poptropolis.promoDive.components 
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class Fish extends Component
	{
		public var wait:Number = 0;
		public var speed:Number = 0;
		public var left:Number;
		public var right:Number;
		public var facingRight:Boolean = true;
		public var startY:Number;
		
		public var timer:int = 0;		
		public var isHit:Boolean = false;
		
		public function Fish(sp:Number, l:Number, r:Number, fr:Boolean, sy:Number)
		{
			speed = sp;
			left = l;
			right = r;
			facingRight = fr;
			startY = sy;
		}
	}
}