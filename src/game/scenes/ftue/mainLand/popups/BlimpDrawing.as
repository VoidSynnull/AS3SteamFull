package game.scenes.ftue.mainLand.popups
{
	import flash.display.DisplayObjectContainer;
	
	import engine.managers.SoundManager;
	
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	
	public class BlimpDrawing extends Popup
	{
		public function BlimpDrawing(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);
			
			this.pauseParent = true;
			this.darkenBackground = true;
			this.autoOpen = true;
			this.groupPrefix = "scenes/ftue/mainLand/";
			this.screenAsset = "plans.swf";
			
			this.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "paper_flap_04.mp3");
			this.letterbox(this.screen.content, null, false);
			loadCloseButton();
		}
	}
}