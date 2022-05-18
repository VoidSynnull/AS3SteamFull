package game.scenes.ftue.adMixed1
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.ftue.FtueEvents;
	import game.scene.template.PlatformerGameScene;
	
	public class AdMixed1 extends PlatformerGameScene
	{
		private var _events:FtueEvents;
		
		public function AdMixed1()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/ftue/adMixed1/";
			
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
