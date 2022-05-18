package game.scenes.con3.expo
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
			configData("finalPopup.swf", "scenes/con3/expo/");
			updateText("You have defeated Omegon and saved humankind. Congratulations!", "THE END");
		}
		
		override public function photoReady(...args):void
		{
			var playerLook:LookData = photo.getPlayerLook();
			
			playerLook.setValue(SkinUtils.EYE_STATE, "open");
//			playerLook.setValue(SkinUtils.FACIAL, "poptropicon_omegon");
//			playerLook.setValue(SkinUtils.HAIR, "poptropicon_omegon");
//			playerLook.setValue(SkinUtils.PACK, "poptropicon_omegon2");
//			playerLook.setValue(SkinUtils.OVERSHIRT, "poptropicon_omegon2");
			
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