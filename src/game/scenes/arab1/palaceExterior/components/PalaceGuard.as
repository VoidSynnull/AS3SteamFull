package game.scenes.arab1.palaceExterior.components
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	public class PalaceGuard extends Component
	{
		public var blinded:Boolean = false;
		public var alerted:Boolean = false;
		public var alert:Signal = new Signal(Entity);
		public var blind:Signal = new Signal(Entity);
		public var alertDistance:Number = 250;
	}
}