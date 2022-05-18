package game.scenes.con3.shared
{
	import flash.geom.Point;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	public class Gauntlets extends Component
	{
		public var controller:Entity;
		public var responder:Entity; 
		
		public var fired:Signal = new Signal();
	}
}