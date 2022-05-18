package game.data.ui
{
	import flash.geom.Point;

	public class GestureData
	{
		public var type:String;//one of the constatnts
		public var start:Point;//starting gesture location :: if null will default to gestures current position
		public var end:Point;//where the gesture will end :: if null will default to start
		public var repeat:int;//how many times the gesture will repeat before the gesture is considered complete
		public var speed:Number;//how long it will take the gesture to move from start to end
		public var onComplete:*;//can be a function or the next GestureData
		public function GestureData(type:String = CLICK, start:Point = null, end:Point = null, repeat:int = 0, speed:Number = 1, onComplete:* = null)
		{
			this.type = type;
			this.start = start;
			this.end = end;
			this.repeat = repeat;
			this.speed = speed;
			this.onComplete = onComplete;
		}
		
		public static const STOP:String 			= "stop";// stops everything
		public static const PRESS:String 			= "press";//gestures that the finger is down
		public static const RELEASE:String 			= "release";//gestures that the finger is up
		public static const CLICK:String 			= "click";//press,release
		public static const MOVE:String 			= "move";//moves the gesture to location on screen
		public static const CLICK_AND_DRAG:String	= "clickAndDrag";//press,move,release
		public static const MOVE_THEN_CLICK:String	= "moveThenClick";//move,press,release
	}
}