package engine.components
{		
	import ash.core.Component;

	public class Id extends Component
	{
		public function Id(id:String = null)
		{
			this.id = id;
		}
		
		public var id:String;
	}
}
