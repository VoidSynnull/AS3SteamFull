package game.scenes.carnival.apothecary
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.data.ui.TransitionData;
	import game.ui.popup.Popup;
	
	public class PosterPopup extends Popup
	{
		public function PosterPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			// call the super class's 'destroy()' method as well to finish cleanup of this group which removes any entites and systems specific to this group, as well as removing the groupContainer.
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			
			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight - 150);
			
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();
			
			super.darkenBackground = true;
			super.groupPrefix = "scenes/carnival/apothecary/";
			super.init(container);
			load();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			//super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["posterPopup.swf"],false,true,loaded);
		}
		
		override public function loaded():void
		{
			//trace("asset:"+super.getAsset("posterPopup.swf", true));
			super.screen = super.getAsset("posterPopup.swf", true) as MovieClip;
			
			//DisplayPositionUtils.centerWithinDimensions(super.screen.content, this.shellApi.viewportWidth, this.shellApi.viewportHeight, 986, 733.45);
			//this.fitToDimensions(this.screen.background, true);
			
			// this loads the standard close button
			super.loadCloseButton();
			
			//super.layout.centerUI(this.screen.content);  // this is returning an error saying that content is not found on __preloader__ ??
			
			//this.centerWithinDimensions(this.screen.content);
			
			super.loaded();
		}
		
		
	}
}