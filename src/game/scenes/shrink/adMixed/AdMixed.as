package game.scenes.shrink.adMixed
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.shrink.shared.groups.ShrinkScene;
	
	public class AdMixed extends ShrinkScene
	{
		public function AdMixed()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/shrink/adMixed/";
			
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