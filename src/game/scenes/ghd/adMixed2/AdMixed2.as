package game.scenes.ghd.adMixed2
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.ghd.GalacticHotDogScene;
	
	public class AdMixed2 extends GalacticHotDogScene
	{
		public function AdMixed2()
		{
			super();
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			super.groupPrefix = "scenes/ghd/adMixed2/";
			
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