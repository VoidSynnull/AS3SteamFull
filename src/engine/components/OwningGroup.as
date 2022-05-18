package engine.components
{	
	import ash.core.Component;
	import engine.group.Group;
	import ash.core.Component;

	public class OwningGroup extends Component
	{
		public function OwningGroup(group:Group = null)
		{
			if(group != null)
			{
				this.group = group;
			}
		}
		
		public var group:Group;
	}
}