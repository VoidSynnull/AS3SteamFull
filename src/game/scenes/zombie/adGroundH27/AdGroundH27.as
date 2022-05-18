package game.scenes.zombie.adGroundH27{
	import flash.display.DisplayObjectContainer;
	
	import game.scene.template.PlatformerGameScene;
	
	public class AdGroundH27 extends PlatformerGameScene
	{
		public function AdGroundH27()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/zombie/adGroundH27/";
			
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