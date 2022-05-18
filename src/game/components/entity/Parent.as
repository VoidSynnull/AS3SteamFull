package game.components.entity
{	
	import ash.core.Component;
	import ash.core.Entity;

	public class Parent extends Component
	{
		public function Parent( parent:Entity = null )
		{
			this.parent = parent;
		}
		public var parent:Entity;
	}
}