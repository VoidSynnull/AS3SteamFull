package game.scenes.survival3.shared.popups
{
	import flash.display.DisplayObjectContainer;
	
	import game.data.character.LookData;
	import game.ui.popup.EpisodeEndingPopup;
	import game.util.SkinUtils;
	
	public class VictoryPopup extends EpisodeEndingPopup
	{
		private const DIALOG_TEXT:String = "at last, you've been found! but where are they taking you?";
		
		public function VictoryPopup(container:DisplayObjectContainer=null)
		{
			super(container);
			updateText(DIALOG_TEXT, "to be continued!");
			configData("survival3_win_popup.swf", "scenes/survival3/shared/popups/");
		}
		
		override public function photoReady( ...args ):void
		{
			var playerLook:LookData = photo.getPlayerLook();
			playerLook.setValue(SkinUtils.MOUTH, "angry");
			playerLook.setValue(SkinUtils.EYE_STATE, "angry");
			photo.addCharacterPose(photo.screen.image.pose, playerLook,onCharLoaded, false);
		}
	}
}