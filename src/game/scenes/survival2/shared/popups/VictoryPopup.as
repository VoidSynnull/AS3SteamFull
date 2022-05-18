package game.scenes.survival2.shared.popups
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import game.data.character.LookData;
	import game.systems.entity.EyeSystem;
	import game.ui.popup.EpisodeEndingPopup;
	import game.util.SkinUtils;
	
	public class VictoryPopup extends EpisodeEndingPopup
	{
		public var _player:Entity;
		private var _currentMouth:String;
		private const DIALOG_TEXT:String = "success! you've caught a delicious fish. but more dangers await you in the woods...";
		
		public function VictoryPopup(container:DisplayObjectContainer=null)
		{
			super(container);
			updateText(DIALOG_TEXT, "to be continued!");
			configData("victoryPopup.swf", "scenes/survival2/shared/victoryPopup/");
		}
		
		override public function photoReady( ...args ):void
		{
			var playerLook:LookData = photo.getPlayerLook();
			playerLook.setValue(SkinUtils.MOUTH, "chew");
			playerLook.setValue(SkinUtils.EYE_STATE, EyeSystem.CASUAL_STILL);
			playerLook.setValue(SkinUtils.ITEM, "empty");
			
			photo.addCharacterPose(photo.screen.box_mc.pose,playerLook,onCharLoaded);
		}
	}
}