package game.scenes.timmy.adStreet3
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.timmy.TimmyScene;
	
	public class AdStreet3 extends TimmyScene
	{
		public function AdStreet3()
		{
			super();
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.groupPrefix = "scenes/timmy/adStreet3/";
			super.init( container );
		}
		
		override public function loaded():void
		{
			super.loaded();
		}
	}
}

