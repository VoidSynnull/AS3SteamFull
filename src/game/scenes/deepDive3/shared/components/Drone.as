package game.scenes.deepDive3.shared.components
{
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	import engine.components.Spatial;
	
	import org.osflash.signals.Signal;
	
	public class Drone extends Component
	{
		public var stateChange:Signal = new Signal(String); // general signal used when changing a state (when i want it to, such as in wake -> idle)
		public var blockPlayer:Boolean = false; // turns on/off collider that will block player's sub
		public var targetSpatial:Spatial; // which spatial the drone should move to or follow (depending on state);
		public var lookAtSpatial:Spatial; // which spatial the drone should "look at"
		public var neanderSpatials:Vector.<Spatial> = new Vector.<Spatial>; // spatial where drone will scan randomly throughout scene. (Optional)
		public var bounds:Rectangle;
		public var scanPlayer:Signal = new Signal();
	}
}