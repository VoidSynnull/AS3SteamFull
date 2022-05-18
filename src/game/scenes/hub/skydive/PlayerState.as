package game.scenes.hub.skydive
{
	import ash.core.Component;
	
	import org.osflash.signals.Signal;
	
	public class PlayerState extends Component
	{
		public function PlayerState()
		{
			this.state = START;
			this.stageChangeRequested = new Signal(String, int);
		}
		
		public function set state(state:String):void
		{
			_state = state;
			_invalidate = true;
			_stageChangeRequestPending = false;
		}
		
		public function get state():String
		{
			return _state;
		}
		
		public function requestStateChange(newState:String, id:int):void
		{
			_stageChangeRequestPending = true;
			this.stageChangeRequested.dispatch(newState, id);
		}
		
		override public function destroy():void
		{
			this.stageChangeRequested.removeAll();
			super.destroy();
		}
		
		public var _stageChangeRequestPending:Boolean = false;
		public var _invalidate:Boolean = false;
		public var local:Boolean = false;
		public var wins:int = 0;
		public var stageChangeRequested:Signal;
		public static const START:String = "start";
		public static const FALL:String = "fall";
		public static const FLOAT:String = "float";
		public static const DEPLOY_CHUTE:String = "deployChute";
		public static const CRASH:String = "crash";
		public static const LAND:String = "land";
		public static const WIN:String = "win";
		public static const LOSE:String = "lose";
		public static const PLAY_AGAIN_CLICKED:String = "playAgainClicked";
		private var _state:String;
	}
}