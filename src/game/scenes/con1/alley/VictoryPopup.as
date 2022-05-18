package game.scenes.con1.alley
{
	import flash.display.DisplayObjectContainer;
	
	import game.data.character.LookData;
	import game.systems.entity.EyeSystem;
	import game.ui.popup.EpisodeEndingPopup;
	import game.util.SkinUtils;
	
	public class VictoryPopup extends EpisodeEndingPopup
	{
		public function VictoryPopup( container:DisplayObjectContainer = null )
		{
			super( container);
			updateText( DIALOG_TEXT, BUTTON_TEXT );
			configData( "breakingIn.swf", "scenes/con1/alley/" );
		}
		
		override public function photoReady( ...args ):void
		{
			var playerLook:LookData = photo.getPlayerLook();
			playerLook.setValue( SkinUtils.ITEM, "empty" );
			playerLook.setValue( SkinUtils.ITEM2, "poptropicon_mjolnir" );
			playerLook.setValue( SkinUtils.EYE_STATE, EyeSystem.CASUAL_STILL);
			photo.addCharacterPose(photo.screen.pose, playerLook, onCharLoaded);
		}
		
		private const DIALOG_TEXT:String = "you're in. the show is about to begin!";
		private const BUTTON_TEXT:String = "to be continued!";
	}
}