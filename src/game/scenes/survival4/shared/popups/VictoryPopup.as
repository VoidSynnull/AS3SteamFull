package game.scenes.survival4.shared.popups
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.util.Command;
	
	import game.components.entity.character.part.SkinPart;
	import game.components.timeline.Timeline;
	import game.data.character.LookData;
	import game.ui.popup.EpisodeEndingPopup;
	import game.util.SkinUtils;
	
	public class VictoryPopup extends EpisodeEndingPopup
	{
		public function VictoryPopup(container:DisplayObjectContainer=null)
		{
			super(container);
			updateText(DIALOG_TEXT, "to be continued");
			configData("endPopup.swf", "scenes/survival4/shared/endPopup/");
		}
		
		override public function photoReady(...args):void
		{
			var playerLook:LookData = photo.getPlayerLook();
			playerLook.setValue(SkinUtils.ITEM, "empty");
			playerLook.setValue(SkinUtils.MOUTH, "cry");
			playerLook.setValue(SkinUtils.EYE_STATE, "angry");
			
			photo.addCharacterPose(photo.screen.image.pose, playerLook, onCharLoaded);
		}
		
		override public function onCharLoaded(char:Entity, allCharactersLoaded:Boolean):void
		{
			SkinUtils.setSkinPart(char, SkinUtils.MOUTH, "cry", true, Command.create(mouthLoaded, char));
		}
		
		private function mouthLoaded(skinPart:SkinPart, char:Entity):void
		{
			SkinUtils.getSkinPartEntity(char, skinPart.id).get(Timeline).gotoAndStop(10);
			super.bitmapDisplay();
		}
		
		private const DIALOG_TEXT:String = "the hunt is on, and you are the quarry!";
	}
}