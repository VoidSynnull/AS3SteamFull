package game.scenes.con3.omegon.omegonLaserControl
{
	import ash.core.Component;
	import ash.core.Entity;
	
	public class OmegonLaserControl extends Component
	{
		public var isLeft:Boolean = false;
		
		public var laser_arm_left:Entity;
		public var laser_arm_right:Entity;
		
		private var _state:String = "";
		internal var _invalidate:Boolean = false;
		
		public function OmegonLaserControl()
		{
			super();
		}
		
		public function get state():String
		{
			return this._state;
		}
		
		public function set state(state:String):void
		{
			this._state = state;
			this._invalidate = true;
		}
	}
}