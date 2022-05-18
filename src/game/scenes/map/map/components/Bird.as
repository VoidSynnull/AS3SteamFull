package game.scenes.map.map.components
{
	import flash.display.Shape;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Display;
	import engine.components.Spatial;
	
	public class Bird extends Component
	{
		public var blimp:Entity;
		public var display:Display;
		public var spatial:Spatial;
		
		public var offsetX:Number = 0;
		public var offsetY:Number = 0;
		
		public var radius:Number;
		
		public var flapRate:Number;
		public var flapTime:Number;
		
		public var flockRate:Number = 1;
		public var flockTime:Number = 0;
		
		public var tempTime:Number = 0;
		
		public var wing1:Shape;
		public var wing2:Shape;
		
		public function Bird(blimp:Entity, flapRate:Number = 8, flapTime:Number = 0, radius:Number = 0)
		{
			this.blimp 		= blimp;
			this.display 	= blimp.get(Display);
			this.spatial	= blimp.get(Spatial);
			
			this.flapRate 	= flapRate;
			this.flapTime 	= flapTime;
			this.radius		= radius;
		}
	}
}