package game.components.entity
{
	import ash.core.Component;
	
	public class Hide extends Component
	{
		public function Hide()
		{
			hidden = false;
		}
		
		public var hidden:Boolean;
	}
}