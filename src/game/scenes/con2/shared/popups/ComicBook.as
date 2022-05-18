package game.scenes.con2.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.ui.popup.Popup;
	
	public class ComicBook extends Popup
	{
		public function ComicBook(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init( container:DisplayObjectContainer=null ):void
		{
			darkenBackground = true;
			groupPrefix = "scenes/" + shellApi.island + "/shared/popups/";
			super.init( container );
			load();
		}
		
		override public function load():void
		{
			loadFiles([ "comic_book.swf" ], false, true, loaded );
		}
		
		override public function loaded():void
		{
			screen = getAsset( "comic_book.swf", true ) as MovieClip;
			loadCloseButton();
			super.loaded();
		}
	}
}