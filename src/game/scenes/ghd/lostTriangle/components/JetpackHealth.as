package game.scenes.ghd.lostTriangle.components
{
	import ash.core.Component;
	
	public class JetpackHealth extends Component
	{
		public const COLORS:Vector.<uint> = new <uint>[ 0xFFFFFF, 0xFFFF33, 0xFF6633, 0xCC0033, 0x55000C ];
		
		public var currentHealthValue:uint = 0;
		public var hurting:Boolean = false;
		public var launched:Boolean = false;
		
		private var _complete:Boolean = false;
		
		public function set complete( isComplete:Boolean ):void
		{
			_complete = isComplete;
		}
		
		public function get complete():Boolean
		{
			return _complete;
		}
	}
}