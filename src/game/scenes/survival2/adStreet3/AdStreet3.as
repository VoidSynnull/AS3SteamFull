package game.scenes.survival2.adStreet3
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.survival2.Survival2Events;
	import game.scene.template.PlatformerGameScene;
	
	public class AdStreet3 extends PlatformerGameScene
	{
		private var _events:Survival2Events;
		
		public function AdStreet3()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival2/adStreet3/";
			
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


