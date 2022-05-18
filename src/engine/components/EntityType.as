package engine.components
{
	import ash.core.Component;
	
	public class EntityType extends Component
	{
		public function EntityType(type:String = null)
		{
			this.type = type;
		}
		
		public var type:String;
	}
}