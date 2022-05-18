package game.scenes.poptropolis.promoDive.components 
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class Jelly extends Component
	{
		public var wait:Number = 0;
		public var speed:Number = 0;
		public var top:Number;
		public var bottom:Number;
		public var goingUp:Boolean = true;
		
		public var timer:int = 0;		
		public var isHit:Boolean = false;
		
		public function Jelly(sp:Number, t:Number, b:Number)
		{
			speed = sp;
			top = t;
			bottom = b;
		}
	}
}