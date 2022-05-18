package game.scenes.con1.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.ui.popup.Popup;
	
	public class Pamphlet extends Popup
	{
		public function Pamphlet(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init( container:DisplayObjectContainer=null ):void
		{
			darkenBackground = true;
			groupPrefix = "scenes/con1/shared/";
			super.init( container );
			load();
		}
		
		override public function load():void
		{
			loadFiles([ "pamphlet.swf" ], false, true, loaded );
		}
		
		override public function loaded():void
		{
			screen = getAsset( "pamphlet.swf", true ) as MovieClip;
			loadCloseButton();
			super.loaded();
		}
	}
}