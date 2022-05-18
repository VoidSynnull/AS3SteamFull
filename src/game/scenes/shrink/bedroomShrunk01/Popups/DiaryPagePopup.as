package game.scenes.shrink.bedroomShrunk01.Popups
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.shrink.ShrinkEvents;
	import game.ui.popup.OneShotPopup;
	
	public class DiaryPagePopup extends OneShotPopup
	{
		public function DiaryPagePopup(container:DisplayObjectContainer=null)
		{
			super(container);
			//fill = false;
			configData("diary_page.swf", "scenes/shrink/bedroomShrunk01/");
		}
		
		public const CLOSE_DIARY:String = "close_diary";
		
		private var shrink:ShrinkEvents;
		
		override public function loaded():void
		{
			super.loaded();
			
			setUp();
		}
		
		private function setUp():void
		{
			if(shellApi.checkEvent(shrink.DIARY_RESTORED))
				content.halfPage.visible = false;
			else
				content.fullPage.visible = false;
		}
		
		override public function close( removeOnClose:Boolean = true, onCloseHandler:Function = null ):void
		{
			shellApi.triggerEvent(CLOSE_DIARY);
			if(shellApi.checkEvent(shrink.DIARY_RESTORED))
				shellApi.triggerEvent(shrink.LEMON_PAPER_LIGHT,true);
			super.close();
		}
	}
}