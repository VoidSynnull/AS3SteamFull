package game.scenes.prison.adMixed2
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.prison.PrisonScene;
	
	public class AdMixed2 extends PrisonScene
	{
		public function AdMixed2()
		{
			super();
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.groupPrefix = "scenes/prison/adMixed2/";
			super.init( container );
		}
		
		override public function loaded():void
		{
			super.loaded();
		}
	}
}

