package game.scenes.custom
{
	import flash.display.DisplayObjectContainer;
	
	/**
	 * Lose game popup for popup game, not quest
	 */
	public class AdLoseGamePopup extends AdLosePopup
	{
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set gametype to Game
			_gameType= "Game";
			super.init(container);
		}
	}
}