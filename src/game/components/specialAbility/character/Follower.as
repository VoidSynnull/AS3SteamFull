package game.components.specialAbility.character
{
	import flash.display.MovieClip;
	
	import ash.core.Component;
	
	import game.components.timeline.Timeline;
	
	public class Follower extends Component
	{
		public var speed:Number = 0.8;
		public var t:Number = 0;
		public var velX:Number = 0;
		public var velY:Number = 0;
		public var accelX:Number = 0;
		public var accelY:Number = 0;
		public var offsetX:Number = 0;
		public var offsetY:Number = 0;
		public var damp:Number = 0.92;
		
		public var flipDisabled:Boolean = false;
		public var flipClip:MovieClip;
		public var swapTimeline:Timeline;
	}
}