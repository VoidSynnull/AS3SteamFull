package game.scenes.deepDive1.deepestOcean
{	
	import flash.display.DisplayObjectContainer;
	
	import game.ui.popup.EpisodeEndingPopup;
	
	public class VictoryPopup extends EpisodeEndingPopup
	{
		public function VictoryPopup(container:DisplayObjectContainer=null)
		{
			super(container);
			updateText("You've discovered something amazing at the bottom of the ocean -- but your mission is just beginning!", "to be continued!");
			configData("victoryPopup.swf", "scenes/deepDive1/deepestOcean/");
		}
	}
}