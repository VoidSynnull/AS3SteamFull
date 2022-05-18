package game.scenes.time.lab.components
{
	import ash.core.Entity;
	
	import ash.core.Component;
	
	import org.osflash.signals.Signal;
	
	public class PushComponent extends Component
	{
		public var pushing:Boolean = false;
		public var startX:Number = 0;
		public var endX:Number = 0;
		public var direction:String = "right";
		public var endReached:Signal = new Signal();
		public var pushZone:Entity;
	}
}