/*
	This component adds a listener attached to the entity's Motion component
	Fires whenever the velocity changes
*/


package game.components.motion
{	
	import flash.geom.Point;
	import ash.core.Component;
	import org.osflash.signals.Signal;
	
	
	public class VelocityListener extends Component
	{
		public var velocityHandler:Signal;
		public var prevVelocityX : Number = 0;
		public var prevVelocityY : Number = 0;
		public var alwaysOn:Boolean;
		private var handler:Function;
		
		
		
		public function VelocityListener( _handler:Function, _alwaysOn:Boolean = false )
		{
			handler = _handler;
			alwaysOn = _alwaysOn;
			velocityHandler = new Signal(Point);
			velocityHandler.add(handler);
		}
		
		public function removeSignal():void
		{
			velocityHandler.remove(handler);
		}
		
	}
}