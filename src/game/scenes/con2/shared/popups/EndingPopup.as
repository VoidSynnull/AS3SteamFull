package game.scenes.con2.shared.popups
{
	import flash.display.DisplayObjectContainer;
	
	import game.data.character.LookData;
	import game.ui.popup.EpisodeEndingPopup;
	import game.util.SkinUtils;
	
	public class EndingPopup extends EpisodeEndingPopup
	{
		public function EndingPopup(container:DisplayObjectContainer=null)
		{
			super(container);
			configData("finalPopup.swf", "scenes/con2/shared/popups/");
			updateText("A REAL VILLAIN HAS CRASHED THE PARTY! CAN YOU SAVE POPTROPICON?", "To be continued!");
		}
		
		override public function photoReady(...args):void
		{
			var playerLook:LookData = photo.getPlayerLook();
			
			playerLook.setValue(SkinUtils.MARKS, "poptropicon_omegon2");
			playerLook.setValue(SkinUtils.FACIAL, "poptropicon_omegon");
			playerLook.setValue(SkinUtils.HAIR, "poptropicon_omegon");
			playerLook.setValue(SkinUtils.PACK, "poptropicon_omegon2");
			playerLook.setValue(SkinUtils.OVERSHIRT, "poptropicon_omegon2");
			
			photo.addCharacterPose(photo.screen.image.pose, playerLook, onCharLoaded);
		}
		
		/*
		override public function onCharLoaded(char:Entity, allCharactersLoaded:Boolean):void
		{
			SkinUtils.setSkinPart(char, SkinUtils.MOUTH, "cry", true, Command.create(mouthLoaded, char));
		}
		
		private function mouthLoaded(skinPart:SkinPart, char:Entity):void
		{
			SkinUtils.getSkinPartEntity(char, skinPart.id).get(Timeline).gotoAndStop(10);
			super.bitmapDisplay();
		}
		*/
	}
}