package game.scenes.ghd.adMixed1
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.ghd.GalacticHotDogScene;
	
	public class AdMixed1 extends GalacticHotDogScene
	{
		public function AdMixed1()
		{
			super();
		}
		
		// pre load setup
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			super.groupPrefix = "scenes/ghd/adMixed1/";
			
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