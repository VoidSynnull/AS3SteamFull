package game.scenes.cavern2.palaceInterior
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.cavern2.shared.Cavern2Scene;
	
	public class PalaceInterior extends Cavern2Scene
	{
		public function PalaceInterior()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/cavern2/palaceInterior/";
			
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