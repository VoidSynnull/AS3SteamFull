package game.scenes.con3.adMixed2
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.con3.Con3Scene;
	
	public class AdMixed2 extends Con3Scene
	{
		public function AdMixed2()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/con3/adMixed2/";
			
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