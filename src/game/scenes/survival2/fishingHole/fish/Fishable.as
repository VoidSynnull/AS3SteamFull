package game.scenes.survival2.fishingHole.fish
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	public class Fishable extends Component
	{
		public const TREADING_STATE:int = 0;
		public const SWIMMING_STATE:int = 1;
		public const BAIT_STATE:int 	= 2;
		
		public var state:int = TREADING_STATE;
		
		public var time:Number = 0;
		public var wait:Number = 0;
		public var minDistance:Number = 10;
		
		public var baitTime:Number = 0;
		public var baitWait:Number = 10;
		
		public var reverseX:Boolean = true;
		
		public var bait:String = "worms";
		public var ignoreBait:Boolean = false;
		
		public var swimArea:Rectangle;
		public var target:Point = new Point();
		
		public function Fishable(swimArea:Rectangle)
		{
			this.swimArea = swimArea;
		}
	}
}