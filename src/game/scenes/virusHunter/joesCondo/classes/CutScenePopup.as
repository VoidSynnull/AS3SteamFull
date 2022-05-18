package game.scenes.virusHunter.joesCondo.classes {

	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.data.animation.Animation;
	import game.data.ui.TransitionData;
	import game.components.entity.VariableTimeline;
	import game.scenes.mocktropica.cheeseInterior.systems.VariableTimelineSystem;
	import game.systems.SystemPriorities;
	import game.ui.popup.Popup;
	
	public class CutScenePopup extends Popup {

		public var cutSceneFileName:String;

		public var useCloseButton:Boolean = false;

		// frame that marks the end of the cutscene.
		//public var endFrameLabel:String = Animation.LABEL_ENDING;

		public var autoPlay:Boolean = true;

		// automatically close when popup reaches the end of animation.
		public var autoClose:Boolean = true;

		// Contains the popup clip's timeline component and runs the timeline, etc.
		private var control:Entity;

		public function CutScenePopup( fileName:String, groupPrefix:String, container:DisplayObjectContainer=null, callback:Function=null ) {

			super( container );

			if ( callback != null ) {
				this.popupRemoved.addOnce( callback );
			}

			this.cutSceneFileName = fileName;

			this.groupPrefix = groupPrefix;

		} //

		// pre load setup
		override public function init( container:DisplayObjectContainer=null ):void {

			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();
			
			super.darkenBackground = true;
			super.init( container );
			this.load();

		} //
		
		// initiate asset load of scene specific assets.
		override public function load():void {

			super.shellApi.loadFile( this.shellApi.assetPrefix + this.groupPrefix + this.cutSceneFileName, this.cutSceneLoaded );

		} //

		// all assets ready
		private function cutSceneLoaded( clip:MovieClip ):void {

			if ( this.getSystem( VariableTimelineSystem ) == null ) {
				this.addSystem( new VariableTimelineSystem(), SystemPriorities.timelineControl );
			}

			super.screen = clip;

			if ( this.useCloseButton ) {
				// this loads the standard close button
				super.loadCloseButton();
			}

			// this centers the movieclip 'content' within examplePopup.swf.  For wide layouts this will center horizontally, for tall layouts vertically.
			//super.layout.centerUI(super.screen.content);

			var tl:VariableTimeline = new VariableTimeline( false );
			tl.onTimelineEnd.add( this.timelineEnded );

			// any entities or systems created within this group will automatically be removed on close.
			this.control = new Entity()
				.add( new Display( clip ), Display )
				.add( tl, VariableTimeline );

			this.addEntity( this.control );

			if ( this.autoPlay ) {
				this.play();
			} else {
				this.stop();
			} //

			super.loaded();

		} //

		// call manually if autoPlay = false.
		public function play():void {

			var tl:VariableTimeline = this.control.get( VariableTimeline ) as VariableTimeline;
			tl.playing = true;

		} //

		public function stop():void {

			var tl:VariableTimeline = this.control.get( VariableTimeline ) as VariableTimeline;
			tl.playing = false;

		} //

		private function timelineEnded( controlEntity:Entity, tl:VariableTimeline ):void {

			tl.playing = false;

			if ( this.autoClose ) {
				this.close();
			}

		} //

		override public function destroy():void {
			
			
			if ( this.control ) {
				
				// do any cleanup required in this Group before calling the super classes destroy method
				var tl:VariableTimeline = this.control.get( VariableTimeline ) as VariableTimeline;
				tl.onTimelineEnd.removeAll();
				
				this.removeEntity( this.control );
				this.control = null;
				
			} //
			
			// call the super class's 'destroy()' method as well to finish cleanup of this group which removes any entites and systems specific to this group, as well as removing the groupContainer.
			super.destroy();
			
		} //

		/**
		 * Retrieve a timeline for controlling playback and speed of cutscene - also for checking individual
		 * cutscene labels.
		 */
		public function getTimelineline():VariableTimeline {
			return this.control.get( VariableTimeline ) as VariableTimeline;
		} //

	} // class

} // package