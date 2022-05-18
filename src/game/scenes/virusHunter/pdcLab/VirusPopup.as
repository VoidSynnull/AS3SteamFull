package game.scenes.virusHunter.pdcLab
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.components.timeline.Timeline;
	import game.data.ui.TransitionData;
	import game.ui.popup.Popup;
	import game.util.DisplayPositions;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	public class VirusPopup extends Popup
	{
		public function VirusPopup(container:DisplayObjectContainer=null)
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
			super.loadFiles(["virusPopup.swf"]);
		}
		
		// all assets ready
		override public function loaded():void
		{
			
			super.screen = super.getAsset("virusPopup.swf", true) as MovieClip;
			// this loads the standard close button
			//super.loadCloseButton();
			
			// this centers the movieclip 'content' within examplePopup.swf.  For wide layouts this will center horizontally, for tall layouts vertically.
			//trace("super.screen:"+super.screen);
			super.layout.centerUI(super.screen.content);
			
			//super.screen.movie.signal.add(endVideo);
			
			movieEntity = new Entity();
			super.addEntity(movieEntity);
			//TimelineUtils.convertClip( MovieClip(_animationsContainer).bird1, this );
			var timelineEntity:Entity = TimelineUtils.convertAllClips(super.screen.content.movie, movieEntity, this);
			var timeline:Timeline = timelineEntity.get(Timeline);
			
			timeline.handleLabel("reachedEnd", endVideo);
			
			super.loaded();
			
			trace("Popup");
		}
		
		public function endVideo():void
		{
			super.close();
		}
		
		private var movieEntity:Entity;
		public var finishedVideo:Signal;
		private var _totalReached:uint = 0;
	}
}