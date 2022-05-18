package game.components.entity.character.part.item
{	
	import ash.core.Component;
	
	public class ItemMotion extends Component
	{
		public var isFront:Boolean = true;		//flag for if item is in front hand or back hand
		private var _state:String = ItemMotion.ROTATE_TO_SHOULDER;
		public function get state():String	{ return _state; }
		public function set state( state:String ):void
		{
			_state = state;
		}
		
		public static const ROTATE_TO_SHOULDER:String = "shoulder";	// default state, makes the item angle towards shoulder with an offset of 90 degrees
		public static const SPIN:String = "spin";
		public static const NONE:String = "";
	
		public var spinCount:int = 0;
		public var spinSpeed:Number = 5;	// angles to rotate each update TODO :: probably need to integrate with time/framerate
		public var isSpinForward:Boolean = true;
		
		public function setSpin( spinCount:int = 1, spinSpeed:Number = 10, spinForward:Boolean = true ):void
		{
			this.spinCount = spinCount;
			this.spinSpeed = spinSpeed;
			this.isSpinForward = spinForward;
			state = ItemMotion.SPIN;
		}
	}
}
