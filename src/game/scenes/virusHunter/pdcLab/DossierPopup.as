package game.scenes.virusHunter.pdcLab
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
		
	import game.data.ui.TransitionData;
	import game.ui.popup.Popup;
	
	public class DossierPopup extends Popup
	{
		public function DossierPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			// call the super class's 'destroy()' method as well to finish cleanup of this group which removes any entities and systems specific to this group, as well as removing the groupContainer.
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			
			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();
			
			super.darkenBackground = true;
			super.groupPrefix = "scenes/virusHunter/pdcLab/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(new Array("dossierPopup.swf"));
		}
		
		// all assets ready
		override public function loaded():void
		{			
			super.screen = super.getAsset("dossierPopup.swf", true) as MovieClip;
			// this loads the standard close button
			super.loadCloseButton();
			// this centers the movieclip 'content' within examplePopup.swf.  For wide layouts this will center horizontally, for tall layouts vertically.
			//trace("super.screen:"+super.screen);
			super.layout.centerUI(super.screen.content);
			
			this.centerWithinDimensions(this.screen.content);
			
			//super.screen.movie.signal.add(endVideo);
			
			super.loaded();
		}
	}
}