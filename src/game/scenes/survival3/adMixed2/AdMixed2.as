package game.scenes.survival3.adMixed2
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.survival3.Survival3Events;
	import game.scene.template.PlatformerGameScene;
	
	public class AdMixed2 extends PlatformerGameScene
	{
		private var _events:Survival3Events;
		
		public function AdMixed2()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival3/adMixed2/";
			
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


