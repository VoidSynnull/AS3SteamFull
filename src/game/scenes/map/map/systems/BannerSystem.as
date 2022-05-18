package game.scenes.map.map.systems
{
	import ash.core.Entity;
	
	import engine.components.SpatialAddition;
	
	import game.components.ui.Book;
	import game.scenes.map.map.nodes.BannerNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class BannerSystem extends GameSystem
	{
		public function BannerSystem()
		{
			super(BannerNode, updateNode);
			
			this._defaultPriority = SystemPriorities.moveComplete;
		}
		
		/**
		 * Eases any map banner that spans multiple pages when changing book pages :: 0229
		 * @auther uhendba 
		 */
		private function updateNode(node:BannerNode, time:Number):void
		{
			if(node.banner.page_start == node.banner.page_end) return; // quit if banner isn't multipage
			
			var entity:Entity = this.group.getEntityById("map");
			if(entity == null) return;	// map not loaded yet, quit
			
			var book:Book= entity.get(Book);
			var addition_map:SpatialAddition = entity.get(SpatialAddition); // urrent  SpatialAddition of the map (Book)
			
			// get linear span of pages (start_x and end_x)
			var start_x:Number = book.pageWidth * (node.banner.page_start - 1);	
			var end_x:Number = book.pageWidth * (node.banner.page_end - 1);
			
			var offsetX:Number; // variable for the offset from start_x
			
			// within
			if(-addition_map.x > start_x && -addition_map.x < end_x)
			{
				offsetX = (start_x + addition_map.x) * -1; // offset set to the current difference of SpatialAddition and start_x
			}
			else if(-addition_map.x <= start_x)
			{
				// left of
				offsetX = 0; // offset set to 0
			}
			else if(-addition_map.x >= end_x)
			{
				// right of
				offsetX = end_x - start_x; // offset set to span length
			}
			
			var deltaX:Number = offsetX - node.addition.x; // change of x
			node.addition.x += deltaX * 12 * time;	// simple easing
		}
	}
}