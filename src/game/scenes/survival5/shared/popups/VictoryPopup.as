package game.scenes.survival5.shared.popups
{
	import flash.display.DisplayObjectContainer;
	
	import game.data.character.LookData;
	import game.ui.popup.EpisodeEndingPopup;
	import game.util.SkinUtils;
	
	public class VictoryPopup extends EpisodeEndingPopup
	{
		public function VictoryPopup(container:DisplayObjectContainer=null)
		{
			super(container);
			updateText(DIALOG_TEXT, "The End");
			configData("endPopup.swf", "scenes/survival5/shared/endPopup/");
		}
		
		override public function photoReady(...args):void
		{
			var playerLook:LookData = photo.getPlayerLook();
			playerLook.setValue(SkinUtils.ITEM, "empty");
			playerLook.setValue(SkinUtils.EYE_STATE, "angry");
			
			photo.addCharacterPose(photo.screen.image.pose, playerLook, onCharLoaded);
		}
		
		override public function transitionComplete():void
		{
			super.transitionComplete();
		}
		
		private const DIALOG_TEXT:String = "You've survived in the woods and thwarted the evil Myron Van Buren. Consider yourself a hero.";
	}
}