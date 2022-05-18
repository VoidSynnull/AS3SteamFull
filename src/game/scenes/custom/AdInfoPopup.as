package game.scenes.custom
{
	import flash.display.DisplayObjectContainer;
	
	/**
	 * Start game popup for quest
	 */
	public class AdInfoPopup extends AdBasePopup
	{
		override public function init(container:DisplayObjectContainer = null):void
		{
			_popupType = "Info";
			// set gametype to Quest
			_gameType= "Quest";
			// clear game ID
			super.campaignData.gameID = "";
			super.init(container);
		}
	}
}