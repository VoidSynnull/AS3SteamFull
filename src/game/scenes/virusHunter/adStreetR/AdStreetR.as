package game.scenes.virusHunter.adStreetR
{
	import flash.display.DisplayObjectContainer;
	import game.scene.template.PlatformerGameScene;
	
	public class AdStreetR extends PlatformerGameScene
	{
		public function AdStreetR()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/virusHunter/adStreetR/";
			
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