package game.scenes.arab3.adMixed1
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.arab3.Arab3Scene;
	
	public class AdMixed1 extends Arab3Scene
	{
		public function AdMixed1()
		{
			super();
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.groupPrefix = "scenes/arab3/adMixed1/";
			super.init( container );
		}
		
		override public function loaded():void
		{
			super.loaded();
		}
	}
}