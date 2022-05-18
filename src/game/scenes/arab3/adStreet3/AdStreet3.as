package game.scenes.arab3.adStreet3
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.arab3.Arab3Scene;
	
	public class AdStreet3 extends Arab3Scene
	{
		public function AdStreet3()
		{
			super();
		}
		
		
		override public function init( container:DisplayObjectContainer=null ):void
		{
			super.groupPrefix = "scenes/arab3/adStreet3/";
			super.init( container );
		}
	}
}