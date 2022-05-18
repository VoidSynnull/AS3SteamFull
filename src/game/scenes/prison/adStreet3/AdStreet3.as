package game.scenes.prison.adStreet3
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.prison.PrisonScene;
	
	public class AdStreet3 extends PrisonScene
	{
		public function AdStreet3()
		{
			super();
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.groupPrefix = "scenes/prison/adStreet3/";
			super.init( container );
		}
		
		override public function loaded():void
		{
			super.loaded();
		}
	}
}

