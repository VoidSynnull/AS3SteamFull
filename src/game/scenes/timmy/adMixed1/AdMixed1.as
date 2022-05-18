package game.scenes.timmy.adMixed1
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.timmy.TimmyScene;
	
	public class AdMixed1 extends TimmyScene
	{
		public function AdMixed1()
		{
			super();
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.groupPrefix = "scenes/timmy/adMixed1/";
			super.init( container );
		}
		
		override public function loaded():void
		{
			super.loaded();
		}
	}
}