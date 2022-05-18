package game.scenes.con1.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.ui.popup.Popup;
	
	public class Selfie extends Popup
	{
		public function Selfie(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			darkenAlpha = .5;
			darkenBackground = true;
			groupPrefix = "scenes/con1/shared/";
			super.init(container);
			load();
		}
		
		override public function load():void
		{
			loadFiles(["selfie.swf"], false, true, loaded);
		}
		
		override public function loaded():void
		{
			screen = getAsset("selfie.swf", true) as MovieClip;
			screen.x *= shellApi.viewportWidth / 960;
			screen.y *= shellApi.viewportHeight / 640;
			loadCloseButton();
			super.loaded();
		}
	}
}