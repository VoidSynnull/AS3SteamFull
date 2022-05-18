package game.scenes.nightWatch.backroom{
	import flash.display.DisplayObjectContainer;
	
	import game.scene.template.PlatformerGameScene;
	
	public class Backroom extends PlatformerGameScene
	{
		public function Backroom()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/nightWatch/backroom/";
			
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