package game.scenes.mocktropica.server
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.ui.popup.Popup;
	
	public class ServerGameInstructionsPopup extends Popup
	{
		private var content:MovieClip;
		
		public function ServerGameInstructionsPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/mocktropica/server/";
			super.screenAsset = "InstructionsPopup.swf";
			
			super.darkenBackground = true;
			super.init(container);
			load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			super.loadCloseButton();
		}
		
		override public function close( removeOnClose:Boolean = true, onCloseHandler:Function = null ):void
		{
			super.close();
		}
	}
}