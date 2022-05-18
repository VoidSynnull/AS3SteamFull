package game.components.entity
{
	import ash.core.Component;
	
	public class Collection extends Component
	{
		public function Collection(id:String)
		{
			this.id = id;
		}
		
		public var id:String;
	}
}