package game.scenes.virusHunter.day2Lungs.data
{
	public class HoleData
	{
		//Keeps track of what the hole number is.
		public var index:uint;
		
		//Spatial component information
		public var x:Number;
		public var y:Number;
		public var rotation:Number;
		
		//Tentacle component information
		public var numSegments:uint;
		
		public var minDistance:Number;
		public var maxDistance:Number;
		
		public var minSpeed:Number;
		public var maxSpeed:Number;
		
		public var minMagnitude:Number;
		public var maxMagnitude:Number;
		
		public function HoleData(index:uint)
		{
			this.index = index;
		}
	}
}