package game.scenes.cavern1.underMainStreet
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.cavern1.shared.Cavern1Scene;
	import game.util.PerformanceUtils;
	
	public class UnderMainStreet extends Cavern1Scene
	{
		public function UnderMainStreet()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/cavern1/underMainStreet/";
			
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
			setupBats();
		}
		
		private function setupBats():void
		{
			for(var i:int = 0; i < NUM_BATS; i++)
			{
				this.convertContainer(_hitContainer["bat"+i], PerformanceUtils.defaultBitmapQuality + .5);
			}
		}
		
		private const NUM_BATS:int = 5
	}
}