package game.scenes.backlot.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.ui.popup.Popup;
	
	public class BacklotBonusComplete extends Popup
	{
		public function BacklotBonusComplete(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/backlot/shared/";
			super.screenAsset = "bonusQuestFinish.swf";
			
			super.darkenBackground = true;
			super.init(container);
			load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			setUp();
			
			super.loadCloseButton();
		}
		
		private var content:MovieClip;
		
		private function setUp():void
		{
			content = screen.content as MovieClip;
			layout.centerUI(content);
		}
		
		override public function close( removeOnClose:Boolean = true, onCloseHandler:Function = null ):void
		{
			super.close();
		}
	}
}