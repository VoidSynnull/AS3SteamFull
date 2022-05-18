package game.scenes.survival2.adMixed2
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.survival2.Survival2Events;
	import game.scene.template.PlatformerGameScene;
	
	public class AdMixed2 extends PlatformerGameScene
	{
		private var _events:Survival2Events;
		
		public function AdMixed2()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival2/adMixed2/";
			
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


