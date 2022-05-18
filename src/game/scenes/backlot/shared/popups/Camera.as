package game.scenes.backlot.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.ui.popup.Popup;
	
	public class Camera extends Popup
	{
		public function Camera(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.pauseParent = false;
			super.darkenBackground = false;
			super.autoOpen = true;
			super.groupPrefix = "scenes/backlot/shared/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["camera.swf"]);
		}
		
		// all assets ready
		override public function loaded():void
		{
	 		this.screen = super.getAsset("camera.swf", true) as MovieClip;
			this.layout.centerUI(this.screen.content);
			
			super.loaded();
		}
	}
}
