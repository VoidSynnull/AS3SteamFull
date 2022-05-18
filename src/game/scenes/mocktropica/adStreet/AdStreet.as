package game.scenes.mocktropica.adStreet
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.mocktropica.MocktropicaEvents;
	import game.scene.template.PlatformerGameScene;
	
	public class AdStreet extends PlatformerGameScene
	{
		private var _events:MocktropicaEvents;
		
		public function AdStreet()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/mocktropica/adStreet/";
			
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