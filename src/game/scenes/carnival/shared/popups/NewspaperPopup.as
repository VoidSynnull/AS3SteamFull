package game.scenes.carnival.shared.popups
{
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.ui.popup.Popup;
	import game.util.SceneUtil;

	
	
	public class NewspaperPopup extends Popup
	{
		public function NewspaperPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			// call the super class's 'destroy()' method as well to finish cleanup of this group which removes any entites and systems specific to this group, as well as removing the groupContainer.
			SceneUtil.lockInput(this, false);
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.darkenBackground = true;
			super.groupPrefix = "scenes/carnival/shared/popups/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(new Array("newspaperPop.swf"));
		}
		
		// all assets ready
		override public function loaded():void
		{			
			super.screen = super.getAsset("newspaperPop.swf", true) as MovieClip;
			super.loadCloseButton();
			//super.layout.centerUI( super.screen.content );
			
			
			
			super.loaded();
		}

	}
}




