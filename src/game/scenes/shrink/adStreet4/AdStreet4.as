package game.scenes.shrink.adStreet4
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.shrink.shared.groups.ShrinkScene;
	
	public class AdStreet4 extends ShrinkScene
	{
		public function AdStreet4()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/shrink/adStreet4/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
		}
	}
}