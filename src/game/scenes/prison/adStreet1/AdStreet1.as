package game.scenes.prison.adStreet1
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.prison.PrisonScene;
	
	public class AdStreet1 extends PrisonScene
	{
		public function AdStreet1()
		{
			super();
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.groupPrefix = "scenes/prison/adStreet1/";
			super.init( container );
		}
		
		override public function loaded():void
		{
			super.loaded();
		}
	}
}