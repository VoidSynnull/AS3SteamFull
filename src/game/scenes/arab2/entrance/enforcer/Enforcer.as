package game.scenes.arab2.entrance.enforcer
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	public class Enforcer extends Component
	{
		public var pathIndex:Number = NaN;
		public var pathTime:Number = 0;
		
		public var captureOffsetY:Number = 50;
		public var hasCaptured:Boolean = false;
		public var captured:Signal = new Signal(Entity, Entity);
		
		public function Enforcer()
		{
			super();
		}
	}
}