package game.scenes.virusHunter.shared.components 
{
	import flash.geom.Point;
	
	import ash.core.Component;
	import engine.components.Spatial;
	
	import game.scenes.virusHunter.shared.data.TentacleDisplayData;
	
	import org.as3commons.collections.ArrayList;
	
	public class Tentacle extends Component
	{
		public static const BORDER_COLOR:uint 	= 0x303315;
		public static const SHADE_COLOR:uint 	= 0x88913C;
		public static const BASE_COLOR:uint		= 0xA6B048;
		
		public var target:Spatial;				//The target Spatial the Tentacle is swinging at, usually the player.
		public var reference:Spatial;			//A reference Spatial used in case the Tentacle is inside a different container.
		
		public var isPaused:Boolean;
		
		//The min/max distance a Tentacle should flail at its fastest/slowest.
		public var minDistance:Number;
		public var maxDistance:Number;
		
		//The min/max magnitude a Tentacle curls between its min/max distance;
		public var minMagnitude:Number;
		public var maxMagnitude:Number;
		
		//The min/max speed a Tentacle swings between its min/max distance;
		public var minSpeed:Number;
		public var maxSpeed:Number;
		
		public var delay:Number;				//Not sure what this does. Haven't tested it.
		public var time:Number;					//Keeps track of time. Or something...
		
		public var segments:ArrayList;			//Segment points in a Tentacle.
		private var numSegments:uint;			//Number of segments in a Tentacle.
		private var segmentLength:uint;			//Length between Tentacle segments.
		
		public var displayData:ArrayList;
		
		public function Tentacle(numSegments:uint = 20, segmentLength:uint = 30, displayData:ArrayList = null)
		{
			this.target = target;
			this.reference = reference;
			
			this.isPaused = false;
			
			this.minDistance = 500;
			this.maxDistance = 800;
			
			this.minMagnitude = 0.01;
			this.maxMagnitude = 0.1;
			
			this.minSpeed = 0.01;
			this.maxSpeed = 5;
			
			this.delay = 0.1;
			this.time = 0;
			
			this.segments = new ArrayList();
			this.numSegments = numSegments;
			this.segmentLength = segmentLength;
			
			for(var i:uint = 0; i <= numSegments; i++)
				this.segments.add(new Point(i * segmentLength, 0));
			
			this.displayData = displayData;
			if(!this.displayData)
			{
				this.displayData = new ArrayList();
				this.displayData.add(new TentacleDisplayData(Tentacle.BORDER_COLOR, 42, 26));
				this.displayData.add(new TentacleDisplayData(Tentacle.SHADE_COLOR, 36, 20));
				this.displayData.add(new TentacleDisplayData(Tentacle.BASE_COLOR, 20, 8));
			}
		}
		
		public function getNumSegments():uint { return this.numSegments; }
		public function setNumSegments(numSegments = 20):void
		{
			this.segments = new ArrayList();
			this.numSegments = numSegments;
			
			for(var i:uint = 0; i <= this.numSegments; i++)
				this.segments.add(new Point(i * this.segmentLength, 0));
		}
		
		public function getSegmentLength():uint { return this.segmentLength; }
		public function setSegmentLength(segmentLength = 20):void
		{
			this.segments = new ArrayList();
			this.segmentLength = segmentLength;
			
			for(var i:uint = 0; i <= this.numSegments; i++)
				this.segments.add(new Point(i * this.segmentLength, 0));
		}
	}
}