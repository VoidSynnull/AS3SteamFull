package game.scenes.con3.adStreet
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.con3.Con3Scene;
	
	public class AdStreet extends Con3Scene
	{
		public function AdStreet()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/con3/adStreet/";
			
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