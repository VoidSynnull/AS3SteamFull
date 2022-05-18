package game.scenes.arab3.adMixed2
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.arab3.Arab3Scene;
	
	public class AdMixed2 extends Arab3Scene
	{
		public function AdMixed2()
		{
			super();
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.groupPrefix = "scenes/arab3/adMixed2/"
			super.init( container );
		}
		
		override public function loaded():void
		{
			super.loaded();
		}
	}
}