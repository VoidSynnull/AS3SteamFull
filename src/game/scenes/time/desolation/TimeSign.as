package game.scenes.time.desolation
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.ui.popup.Popup;
	
	public class TimeSign extends Popup
	{
		public function TimeSign(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.pauseParent = true;
			super.darkenAlpha = .8;
			super.darkenBackground = true;
			super.groupPrefix = "scenes/time/desolation/";
			super.init(container);
			load();
		}
		
		override public function load():void
		{
			super.shellApi.loadFiles(["assets/scenes/time/desolation/timeSign.swf"],loadComplete);
		}
		
		public function loadComplete():void
		{
			super.screen = super.getAsset("timeSign.swf", true) as MovieClip;
			super.loadCloseButton();
			super.layout.centerUI(super.screen.content);
			super.loaded();
		}
	}
}