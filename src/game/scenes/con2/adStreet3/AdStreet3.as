package game.scenes.con2.adStreet3
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.con2.shared.Poptropicon2Scene;
	
	public class AdStreet3 extends Poptropicon2Scene
	{
		public function AdStreet3()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/con2/adStreet3/";
			
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