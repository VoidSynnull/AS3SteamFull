package game.scenes.shrink.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import game.creators.ui.ButtonCreator;
	import game.scenes.shrink.ShrinkEvents;
	import game.scenes.shrink.silvaOfficeShrunk01.SilvaOfficeShrunk01;
	import game.scenes.shrink.silvaOfficeShrunk02.SilvaOfficeShrunk02;
	import game.ui.popup.Popup;
	
	public class LooseScreen extends Popup
	{
		public function LooseScreen(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/shrink/shared/popups/";
			super.screenAsset = "lose_screen.swf";
			
			super.darkenBackground = true;
			super.init(container);
			load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			content = screen.content;
			
			layout.centerUI(content);
			
			setUp();
		}
		
		private function setUp():void
		{
			ButtonCreator.createButtonEntity(content.btnRetry, this, retry, null, null, null, true, true);
			ButtonCreator.createButtonEntity(content.btnQuit, this, quit, null, null, null, true, true);
		}
		
		private function retry( entity:Entity ):void
		{
			shellApi.loadScene( SilvaOfficeShrunk01, 3320, 1290, "left" );
		}
		
		private function quit( entity:Entity ):void
		{
			shellApi.loadScene( SilvaOfficeShrunk02, 1400, 400, "left" );
		}
		
		private var shrinkRay:ShrinkEvents;
		
		private var content:MovieClip;
	}
}