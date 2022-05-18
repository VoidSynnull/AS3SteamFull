package game.scenes.map.map.groups
{
	import flash.display.DisplayObjectContainer;
	
	import engine.group.DisplayGroup;
	
	public class PageItem extends DisplayGroup
	{
		public var islandFolder:String;
		public var pageFolder:String;
		public var x:Number;
		public var y:Number;
		
		public function PageItem(container:DisplayObjectContainer = null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.init(container);
			
			this.groupContainer.x = this.x;
			this.groupContainer.y = this.y;
			
			this.groupPrefix = this.islandFolder + this.pageFolder;
		}
	}
}