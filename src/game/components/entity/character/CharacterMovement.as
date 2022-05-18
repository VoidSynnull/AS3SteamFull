package game.components.entity.character
{
	import ash.core.Component;
	
	public class CharacterMovement extends Component
	{

		private var _active:Boolean = false;
		public function get active():Boolean 	{ return _active; }
		public function set active( value:Boolean ):void 	
		{ 
			_active = value;
			if( !_active )
			{
				_state = NONE;
			}
		}
		
		private var _state:String = NONE;
		public function get state():String 	{ return _state; }
		public function set state( value:String ):void 	
		{ 
			_state = value;
			active = (_state != NONE);
		}
		
		public static const NONE:String 			= "none";
		public static const AIR:String 				= "air";
		public static const GROUND:String 			= "ground";
		public static const GROUND_FRICTION:String 	= "ground_friction";
		public static const CLIMB:String 			= "climb";
		public static const DIVE:String 			= "dive";
		public static const GRAVITY:String 			= "gravity";
		
		public var adjustHeadWithVelocity:Boolean = true;
	}
}