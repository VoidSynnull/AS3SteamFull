package game.scenes.arab3.commonRoom
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.arab3.Arab3Scene;
	
	public class CommonRoom extends Arab3Scene
	{
		public function CommonRoom()
		{
			super();
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.groupPrefix = "scenes/arab3/commonRoom/";
			super.init( container );
		}
	}
}