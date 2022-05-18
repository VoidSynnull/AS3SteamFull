package game.scenes.examples.signalExample.components
{
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	import org.osflash.signals.Signal;

	/**
	 * shadow: The Signal that accepts a function with a Boolean param from the scene
	 * zone: Rectangle specifying the bounds of the "room" in the scene
	 * inZone: Flag that prevents the Signal from being dispatched on every system update if your position hasn't changed
	 */
	public class Shadow extends Component
	{
		public var shadow:Signal;
		
		public var zone:Rectangle;
		public var inZone:Boolean;
		
		public function Shadow(handler:Function, inZone:Boolean, x:Number, y:Number, width:Number, height:Number)
		{
			shadow = new Signal(Boolean);
			shadow.add(handler);
			
			this.inZone = inZone;
			this.zone = new Rectangle(x, y, width, height);
		}
	}
}