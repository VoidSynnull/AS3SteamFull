package game.scenes.ghd.adStreet1
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.ghd.GalacticHotDogScene;
	
	public class AdStreet1 extends GalacticHotDogScene
	{
		public function AdStreet1()
		{
			super();
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			super.groupPrefix = "scenes/ghd/adStreet1/";
			
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