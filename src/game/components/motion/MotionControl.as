package game.components.motion
{
	import ash.core.Component;

	public class MotionControl extends Component
	{
		public function MotionControl()
		{
			//this.reachedFinalPoint = new Signal( Entity );
		}
		
		// input
		public var lockInput:Boolean = false;		// lock inputActive flag, so it is not update Input.inputActive
		public var inputActive:Boolean = false;		// == Input.inputActive
		public var inputStateChange:Boolean = false;
		public var inputStateDown:Boolean = false;

		// movement
		public var forceTarget:Boolean;				// if true, moveToTarget is always true
		public var moveToTarget:Boolean;			// if entity should move toward target
	}
}