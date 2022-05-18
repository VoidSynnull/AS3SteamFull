package game.managers.stateMachine
{
	
	public class StateMachineMessage
	{
		public static const EXIT_CALLBACK:String = "exit";
		public static const ENTER_CALLBACK:String = "enter";
		public static const TRANSITION_COMPLETE:String = "transition complete";
		public static const TRANSITION_DENIED:String = "transition denied";
		
		public var message : String;
		public var fromState : String;
		public var toState : String;
		public var currentState : String;
		public var allowedStates : Object;

		public function StateMachineMessage( message:String = "" )
		{
			this.message = message;
		}
	}
}