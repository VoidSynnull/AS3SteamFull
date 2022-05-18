package game.scenes.mocktropica.shared.components
{
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Spatial;
	
	import org.osflash.signals.Signal;
	
	public class Narf extends Component
	{
		public function Narf()
		{
			targetChanged = new Signal(Spatial, Entity);
			petChew = new Signal();
		}
		
		public var walkSpeed:Number;
		public var runSpeed:Number;
		public var jumpHeight:Number;
		public var randDist:Number;
		
		public var targetChanged:Signal;
		public var petChew:Signal;
		public var currentCurd:Entity;
		public var targetCurd:Boolean = false;
	}
}