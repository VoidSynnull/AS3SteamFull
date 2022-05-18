package game.scenes.myth.adGroundH9R
{		
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.myth.shared.MythScene;
	
	public class AdGroundH9R extends MythScene 
	{
		public function AdGroundH9R()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/myth/adGroundH9R/";
			super.init(container);
		}
	}
}
