package game.scenes.carnival.adStreet2
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.carnival.CarnivalEvents;
	import game.scene.template.PlatformerGameScene;
	
	public class AdStreet2 extends PlatformerGameScene
	{
		private var _events:CarnivalEvents;
		
		public function AdStreet2()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carnival/adStreet2/";
			
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