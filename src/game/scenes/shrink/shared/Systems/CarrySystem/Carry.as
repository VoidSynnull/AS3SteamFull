package game.scenes.shrink.shared.Systems.CarrySystem
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	public class Carry extends Component
	{
		public var carrier:Entity;
		public var pickUpDropItem:Signal;
		
		public function get holding():Boolean{return carrier != null;}
		
		public function Carry()
		{
			pickUpDropItem = new Signal(Entity, Boolean);
		}
	}
}