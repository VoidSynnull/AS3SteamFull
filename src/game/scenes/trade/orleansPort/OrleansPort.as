package game.scenes.trade.orleansPort
{
	import flash.display.DisplayObjectContainer;
	
	import game.scene.template.PlatformerGameScene;
	
	public class OrleansPort extends PlatformerGameScene
	{
		public function OrleansPort()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/trade/orleansPort/";
			
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


