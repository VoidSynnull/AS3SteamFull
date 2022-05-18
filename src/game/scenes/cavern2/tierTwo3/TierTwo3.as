package game.scenes.cavern2.tierTwo3
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.cavern2.shared.Cavern2Scene;
	
	public class TierTwo3 extends Cavern2Scene
	{
		public function TierTwo3()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/cavern2/tierTwo3/";
			
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