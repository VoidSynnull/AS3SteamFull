package game.scenes.myth.adGroundH9
{		
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.myth.shared.MythScene;
	
	public class AdGroundH9 extends MythScene
	{
		public function AdGroundH9()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/myth/adGroundH9/";
			super.init(container);
		}
	}
}
