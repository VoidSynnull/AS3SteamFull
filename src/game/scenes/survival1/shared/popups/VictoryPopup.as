package game.scenes.survival1.shared.popups
{
	import flash.display.DisplayObjectContainer;
	
	import game.data.character.LookData;
	import game.systems.entity.EyeSystem;
	import game.ui.popup.EpisodeEndingPopup;
	import game.util.SkinUtils;
	
	public class VictoryPopup extends EpisodeEndingPopup
	{
		private const DIALOG_TEXT:String = "success! you've made it through the night. but are you ready for what happens next?";
		
		public function VictoryPopup(container:DisplayObjectContainer=null)
		{
			super(container);
			updateText(DIALOG_TEXT, "to be continued!");
			configData("victoryPopup.swf", "scenes/survival1/shared/victoryPopup/");
		}
		
		override public function photoReady(...args):void
		{
			var playerLook:LookData = photo.getPlayerLook();
			playerLook.setValue(SkinUtils.EYE_STATE, EyeSystem.CLOSED);
			photo.addCharacterPose(photo.screen.image.pose,playerLook,onCharLoaded);
		}
	}
}