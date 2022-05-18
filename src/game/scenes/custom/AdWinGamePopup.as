package game.scenes.custom
{
	import flash.display.DisplayObjectContainer;
	
	/**
	 * Win game popup for popup game, not quest
	 */
	public class AdWinGamePopup extends AdWinPopup
	{
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set gametype to Game
			_gameType= "Game";
			super.init(container);
		}
	}
}