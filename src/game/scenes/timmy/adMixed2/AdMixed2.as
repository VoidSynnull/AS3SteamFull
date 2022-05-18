package game.scenes.timmy.adMixed2
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.timmy.TimmyScene;
	
	public class AdMixed2 extends TimmyScene
	{
		public function AdMixed2()
		{
			super();
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.groupPrefix = "scenes/timmy/adMixed2/";
			super.init( container );
		}
		
		override public function loaded():void
		{
			super.loaded();
		}
	}
}

