package game.scenes.backlot.backlotTopDown
{
	import flash.display.DisplayObjectContainer;
	
//	import game.scene.template.PlatformerGameScene;
	
	public class BacklotTopDown extends CartScene //game.scenes.backlot.shared.CartScene
	{
		public function BacklotTopDown()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/backlot/backlotTopDown/";
			
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