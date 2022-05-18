package game.comicViewer.components
{
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	public class StayInBounds extends Component
	{
		public function StayInBounds(rec:Rectangle)
		{
			bounds = rec;
		}
		
		public var bounds:Rectangle;
		public var hitEdge:Boolean = false;
	}
}