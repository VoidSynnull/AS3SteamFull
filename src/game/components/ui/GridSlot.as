package game.components.ui
{
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	import org.osflash.signals.Signal;

	public class GridSlot extends Component
	{
		public function GridSlot()
		{
		}
		
		public var onActivated:Signal = new Signal();
		public var onDeactivated:Signal = new Signal();
		
		public var invalidate:Boolean;
		
		private var _active:Boolean;
		public function get active():Boolean	{ return _active; }
		
		public var reposition:Boolean;
		public var resize:Boolean;
		
		private var _deactivate:Boolean;
		public function get deactivate():Boolean	{ return _deactivate; }
		public function set deactivate( value:Boolean ):void	
		{ 
			_deactivate = value
			if( _deactivate )
			{
				_activate = false;
				_active = false;
			}
		}
		
		private var _activate:Boolean;
		public function get activate():Boolean	{ return _activate; }
		public function set activate( value:Boolean ):void	
		{ 
			_activate = _active = value
			if( _activate )
			{
				_deactivate = false;
			}
			
		}
		
		public var id:String;
		public var index:int;
		public var slotRect:Rectangle;
		
		public var offsetXPercent:Number = .5;
		public var offsetYPercent:Number = .5;

	}
}