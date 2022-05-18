package game.components.scene
{
	import ash.core.Component;
	
	public class Vehicle extends Component
	{
		public function Vehicle()
		{
			super();
		}
		
		public var locked:Boolean = false;
		public var engineSoundFadeOut:Boolean = false;
		public var onlyRotateOnAccelerate:Boolean;   // If true we only turn when accelerating (usually for cars/trucks).
	}
}