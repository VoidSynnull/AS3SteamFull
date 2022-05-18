package game.scenes.virusHunter.adStreet
{
	import flash.display.DisplayObjectContainer;
	import game.scene.template.PlatformerGameScene;
	
	public class AdStreet extends PlatformerGameScene
	{
		public function AdStreet()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/virusHunter/adStreet/";
			
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