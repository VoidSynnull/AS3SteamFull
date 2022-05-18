package game.scenes.poptropolis.promoDive.components 
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class Shark extends Component
	{
		public var wait:Number = 0;
		public var speed:Number = 0;
		public var left:Number;
		public var right:Number;
		public var facingRight:Boolean;
		
		public var timer:int = 0;		
		public var isHit:Boolean = false;
		public var attacking:Boolean = false;
		
		public function Shark(sp:Number, l:Number, r:Number, fr:Boolean)
		{
			speed = sp;
			left = l;
			right = r;
			facingRight = fr;
		}
	}
}