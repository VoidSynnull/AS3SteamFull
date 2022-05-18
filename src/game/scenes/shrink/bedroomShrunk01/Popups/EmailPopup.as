package game.scenes.shrink.bedroomShrunk01.Popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.ui.popup.Popup;
	
	public class EmailPopup extends Popup
	{
		public function EmailPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/shrink/bedroomShrunk01/";
			super.screenAsset = "email.swf";
			
			super.darkenBackground = true;
			super.init(container);
			load();
		}
		
		public const CLOSE_EMAIL:String = "close_email";
		
		private var content:MovieClip;
		
		override public function loaded():void
		{
			super.loaded();
			
			content = screen.content as MovieClip;
			
			layout.centerUI(content);
			
			super.loadCloseButton();
		}
		
		override public function close( removeOnClose:Boolean = true, onCloseHandler:Function = null ):void
		{
			shellApi.triggerEvent(CLOSE_EMAIL);
			super.close();
		}
	}
}