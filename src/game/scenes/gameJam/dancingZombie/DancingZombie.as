package game.scenes.gameJam.dancingZombie
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	
	import game.scene.template.PlatformerGameScene;
	
	public class DancingZombie extends PlatformerGameScene
	{
		public function DancingZombie()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/gameJam/dancingZombie/";
			
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
			
			addChildGroup(new DanceGamePopup(overlayContainer));
		}
		
		override protected function addUI(container:Sprite):void
		{
			// don't add UI
		}
	}
}