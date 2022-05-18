package game.scenes.custom
{
	import flash.display.DisplayObjectContainer;
	
	/**
	 * Start game popup for popup game, not quest
	 */
	public class AdStartGamePopup extends AdStartPopup
	{
		override public function init(container:DisplayObjectContainer = null):void
		{
			
			super.shellApi.logWWW("AdStartGamePopup");
			//if(_popupScene)
				//_gameType= "Quest";
			//else
				_gameType= "Game";
			super.init(container);
		}
	}
}