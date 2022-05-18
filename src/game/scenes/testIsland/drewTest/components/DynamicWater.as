package game.scenes.testIsland.drewTest.components
{
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	import org.as3commons.collections.ArrayList;

	public class DynamicWater extends Component
	{
		public var resetSurface:Boolean;
		public var resetPoints:Boolean;
		
		public var box:Rectangle;
		public var height:Number;
		
		public var numPoints:int;
		public var points:ArrayList;
		
		public var minSpeed:Number;
		public var maxSpeed:Number;
		
		public var minMagnitude:Number;
		public var maxMagnitude:Number;
		
		public var speedFactor:Number;
		public var magnitudeFactor:Number;
		
		public var speedDecay:Number;
		public var magnitudeDecay:Number;
		public var time:Number;
		
		public function DynamicWater(box:Rectangle, height:Number, numPoints:int)
		{
			this.resetSurface = true;
			this.resetPoints = true;
			this.box = box;
			this.height = height;
			
			this.numPoints = numPoints;
			this.points= new ArrayList();
			
			this.minSpeed = 1;
			this.maxSpeed = 10;
			
			this.minMagnitude = 1;
			this.maxMagnitude = 30;
			
			this.speedFactor = 0.02;
			this.magnitudeFactor = 0.06;
			
			this.speedDecay = 3;
			this.magnitudeDecay = 10;
			this.time = 0;
		}
	}
}