package game.scenes.shrink.livingRoomShrunk.StaticSystem
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class StaticBalloon extends Component
	{
		public var origin:Point;
		public var returnTime:Number;
		public var stickingEntity:Static;
		public var returning:Boolean;
		public var home:Boolean;
		
		public function StaticBalloon(origin:Point, returnTime:Number = 3)
		{
			this.origin = origin;
			this.returnTime = returnTime;
			
			returning = false;
			home = true;
			stickingEntity = null;
		}
		
		public function hitBalloon(static:Static = null):void
		{
			stickingEntity = static;
			home = false;
			returning = false;
		}
	}
}