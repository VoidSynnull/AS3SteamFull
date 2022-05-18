package game.scenes.myth.adStreet
{		
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.myth.shared.MythScene;
	
	public class AdStreet extends MythScene
	{
		public function AdStreet()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/myth/adStreet/";
			super.init(container);
		}
	}
}
