package game.scenes.shrink.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.scenes.shrink.ShrinkEvents;
	import game.ui.popup.Popup;
	
	public class MicroscopeMessage extends Popup
	{
		public function MicroscopeMessage(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/shrink/shared/popups/";
			super.screenAsset = "microscope_message.swf";
			
			super.darkenBackground = true;
			super.init(container);
			load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			content = screen.content;
			
			layout.centerUI(content);
			
			super.loadCloseButton();
		}
		
		override public function close( removeOnClose:Boolean = true, onCloseHandler:Function = null ):void
		{
			super.shellApi.triggerEvent( shrinkRay.LOOK_AWAY_MICROSCOPE );
			super.close();
		}
		
		private var shrinkRay:ShrinkEvents;
		
		private var content:MovieClip;
	}
}