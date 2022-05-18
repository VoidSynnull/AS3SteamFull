package game.scenes.ftue.intro
{
	import flash.display.DisplayObjectContainer;
	
	import game.data.character.LookData;
	import game.ui.elements.DialogPicturePopup;
	import game.util.SkinUtils;
	
	public class TutorialPopup extends DialogPicturePopup
	{
		private const SKIP_TUTORIAL_TEXT:String = "LEAVE";
		private const CANCEL_TEXT:String = "STAY";
		private const DIALOG_TEXT:String = "Are you sure you want to bail out and leave the tutorial?";
		
		public function TutorialPopup(container:DisplayObjectContainer=null)
		{
			super(container, false, true);
			updateText(DIALOG_TEXT, SKIP_TUTORIAL_TEXT, CANCEL_TEXT);
			configData("tutorialPopup.swf", "scenes/ftue/intro/");
		}
		
		override public function photoReady( ...args ):void
		{
			var playerLook:LookData = photo.getPlayerLook();
			playerLook.setValue( SkinUtils.PACK, "parachute");
			photo.addCharacterPose(photo.screen.pose, playerLook, onCharLoaded);
		}
		
	}
}