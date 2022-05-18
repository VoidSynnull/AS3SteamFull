package game.components.entity.character.part
{
	import flash.display.MovieClip;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	public class GooglyEyes extends Component
	{
		public var left:MovieClip;
		public var right:MovieClip;
		public var npc:Entity;
		public var time:Number = 0;
		public var baseSpeed:Number = 20;
		public var extraSpeed:Number = 0;
		public var moveMultiplier:Number = 8;
		public var timeMultiplier:Number = 0.3;
		
		// from component xml as strings
		public var speed:String;
		public var moveFactor:String;
		public var timeFactor:String;
		
		public function GooglyEyes()
		{
		}
	}
}
