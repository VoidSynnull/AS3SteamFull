package game.scenes.mocktropica.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.ui.popup.Popup;
	
	public class Script extends Popup
	{
		public function Script( container:DisplayObjectContainer = null )
		{
			super( container );

		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{

			super.darkenBackground = true;
			super.groupPrefix = "scenes/mocktropica/shared/";
			super.init(container);
			load();
			
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce( loaded );
			super.loadFiles( new Array( "script.swf" ));
		}
		
		override public function loaded():void
		{
			
			super.screen = super.getAsset("script.swf", true) as MovieClip;
			super.loadCloseButton();
			super.layout.centerUI( super.screen.content );	
			
			super.loaded();
			super.open();
		}
		
	
	}
}


