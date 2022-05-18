package game.scenes.deepDive1.shared.data
{
	import flash.geom.Point;

	public class FishPathData
	{
		public function FishPathData( targetPosition:Point, speed:Number = 1, rotation:Number = 0, delay:Number = 1, filmable:Boolean = false, progressConditional:* = null, swimStyle:SwimStyle =null){
			this.speed=speed;
			this.delay=delay;
			this.delayCounter=0;
			this.targetPosition=targetPosition;
			this.filmable=filmable;
			this.progressConditional=progressConditional;
			this.swimStyle=swimStyle;
			this.rotation = rotation;
		}
		static public const RIGHT:Number = 0;
		static public const LEFT:Number = 180;
		static public const DOWN:Number = 90;
		static public const UP:Number = -90;
		
		public var speed:Number;
		public var delay:Number;
		public var targetPosition:Point;
		public var filmable:Boolean;
		public var rotation:Number = RIGHT;
		public var progressConditional:*;
		public var swimStyle:SwimStyle;
		public var delayCounter:Number = 0;
	}
}