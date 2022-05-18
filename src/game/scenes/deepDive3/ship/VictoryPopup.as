package game.scenes.deepDive3.ship
{	
	import flash.display.DisplayObjectContainer;
	
	import game.ui.popup.EpisodeEndingPopup;
	
	public class VictoryPopup extends EpisodeEndingPopup
	{
		public function VictoryPopup(container:DisplayObjectContainer=null)
		{
			super(container);
			updateText("You uncovered the mystery of Atlantis and returned to the surface. congratulations!", "to be continued!");
			configData("victoryPopup.swf", "scenes/deepDive3/ship/");
		}
	}
}