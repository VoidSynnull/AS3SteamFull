package game.scenes.map.map.components
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import game.scenes.map.map.groups.PageItem;
	
	public class PageItemSlide extends Component
	{
		public var pageItem:PageItem;
		public var buttons:Vector.<Entity> = new Vector.<Entity>();
		
		public function PageItemSlide()
		{
			
		}
	}
}