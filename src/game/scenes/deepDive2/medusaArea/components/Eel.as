package game.scenes.deepDive2.medusaArea.components 
{
	//import flash.geom.Point;
	
	import ash.core.Component;
	
	//import engine.components.Spatial;
	
	public class Eel extends Component
	{
		public var stung:Boolean = false;
		public var angle:Number = 0;
		
		public var speed:Number = 0;
		public var left:Number;
		public var right:Number;
		public var facingRight:Boolean;
		
		public var attacking:Boolean = false;
		
		public function Eel(sp:Number, l:Number, r:Number, fr:Boolean)
		{
			speed = sp;
			left = l;
			right = r;
			facingRight = fr;
		}
	}
}