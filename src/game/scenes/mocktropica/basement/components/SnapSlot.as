package game.scenes.mocktropica.basement.components
{
	import ash.core.Entity;
	
	import ash.core.Component;
	
	// link between things that snap together
	public class SnapSlot extends Component
	{
		public var snappedEnt:Entity = null;
		public var occupied:Boolean = false;
	}
}