package game.data.motion.time
{
	public class FixedTimestep
	{
		public function FixedTimestep()
		{
		}
		
		public static var MOTION_TIME:Number = 1 / 30;
		public static const MOTION_LINK:String = "motion";
		public static var ANIMATION_TIME:Number = 1 / 32;
		public static const ANIMATION_LINK:String = "animation";
	}
}