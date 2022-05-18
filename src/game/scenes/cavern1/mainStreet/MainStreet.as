package game.scenes.cavern1.mainStreet
{
	import flash.display.DisplayObjectContainer;
	
	import game.components.entity.Dialog;
	import game.scenes.cavern1.shared.Cavern1Scene;
	import game.ui.elements.DialogPicturePopup;
	
	public class MainStreet extends Cavern1Scene
	{
		public function MainStreet()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/cavern1/mainStreet/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			if(!shellApi.checkHasItem(cavern1.BUTTON))
			{
				var popup:DialogPicturePopup = new DialogPicturePopup(overlayContainer);
				popup.configData("introPopup.swf","scenes/con1/shared/introPopup/");
				popup.updateText("A supervolcano may be about to erupt. Help the scientists fix their equipment!", "START");
				popup.removed.add(startIntro);
				addChildGroup(popup);
			}
			else
			{
				gotButton();
			}
		}
		
		private function startIntro(popup:DialogPicturePopup):void
		{
			performAction("introNpc", gotButton);
		}
		
		private function gotButton(...args):void
		{
			Dialog(getEntityById("jane").get(Dialog)).setCurrentById("howdy");
		}
	}
}