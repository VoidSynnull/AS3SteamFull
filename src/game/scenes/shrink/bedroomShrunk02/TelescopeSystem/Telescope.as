package game.scenes.shrink.bedroomShrunk02.TelescopeSystem
{
	import flash.text.TextField;
	
	import ash.core.Component;
	
	import game.scenes.shrink.shared.Systems.WalkToTurnDialSystem.WalkToTurnDial;
	
	public class Telescope extends Component
	{
		public var dials:Vector.<WalkToTurnDial>;
		public var displays:Vector.<TextField>;
		
		public var totalDisplayedAngle:Number;
		
		public var maxAngle:Number;
		
		public var defaultAngle:Number; 
		public var rotationScale:Number;
		
		public function Telescope(defaultAngle:Number = 0, rotationScale:Number = 0, maxAngle:Number = 100)
		{
			displays = new Vector.<TextField>();
			dials = new  Vector.<WalkToTurnDial>();
			this.defaultAngle = defaultAngle;
			this.rotationScale = rotationScale;
			totalDisplayedAngle = 0;
			this.maxAngle = maxAngle;
		}
	}
}