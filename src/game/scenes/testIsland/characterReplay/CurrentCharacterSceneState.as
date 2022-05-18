package game.scenes.testIsland.characterReplay
{
	import ash.core.Component;
	
	public class CurrentCharacterSceneState extends Component
	{
		public var invalidate:Boolean = false;
		public var timeInState:Number = 0;
		public var previousState:CharacterSceneState;
		private var _state:CharacterSceneState;
		
		public function set state(state:CharacterSceneState):void
		{
			if(_state != state)
			{
				invalidate = true;
				previousState = _state;
				_state = state;
			}
		}
		
		public function get state():CharacterSceneState
		{
			return _state;
		}
	}
}