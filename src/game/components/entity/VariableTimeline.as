package game.components.entity {

	import flash.display.MovieClip;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import game.data.animation.LabelHandler;
	
	import org.osflash.signals.Signal;

	/**
	 * This is just a timeline that allows you to control the rate/speed at which the timeline advances.
	 * I imagine the regular timeline will have this functionality added at some point, but it doesn't
	 * have it yet, and I need it now.
	 */
	public class VariableTimeline extends Component {

		/**
		 * signal with entity, timline passed as variables.
		 * onTimelineEnd( e:Entity, new_label:String )
		 */
		public var onTimelineEnd:Signal;

		/**
		 * Called when the current movieclip label changes: flash only counts the last label from all the layers as a current label.
		 * onLabelReached( e:Entity, label:String )
		 */
		public var onLabelReached:Signal;

		/**
		 * Rate at which timeline advances. 2.0 is double speed.
		 */
		public var rate:Number = 1.0;
		
		public var playing:Boolean = false;
		public var reverse:Boolean = false;
		public var loop:Boolean;


		public var currentFrame:int;
		//public var _lastFrame:int;			// used to check for label dispatching.

		public var maxFrames:int;

		/**
		 * Time accumulator.
		 */
		public var _accumulator:Number;

		/**
		 * Go directly to this frame on next update.
		 */
		public var _gotoFrame:Object;

		/**
		 * labelHandler( entity, timeline )
		 * Surely if you wanted the 'label' as a parameter, you should have used onLabelReached() instead.
		 */
		public var _labelHandlers:Vector.<LabelHandler>;

		public function VariableTimeline( looping:Boolean=true ) {

			this.loop = looping;

			this.onTimelineEnd = new Signal( Entity, VariableTimeline );
			this.onLabelReached = new Signal( Entity, String );

		} //

		/**
		 * Reset the component to use a new display object. Call when the Display component's display is changed.
		 */
		public function resetWith( displayObject:MovieClip ):void {

			this.maxFrames = displayObject.totalFrames;
			this.currentFrame = 1;
			this._accumulator = 0;
			this._gotoFrame = 0;

		} //

		/**
		 * Due to the messy nature of Entity systems, the frame will not actually change
		 * until the VariableTimeline system gets a chance to run - it will lag behind
		 * by a frame.
		 * 
		 * This leads to a very obnoxious side effect: if you query the 'currentFrame'
		 * after calling gotoAndStop(), the frame will reflect the old value. There is
		 * no good way around this in an entity system.
		 */
		public function gotoAndStop( frame:Object ):void {

			this._gotoFrame = frame;
			this.playing = false;

		} //

		/**
		 */
		public function gotoAndPlay( frame:Object ):void {

			this._gotoFrame = frame;
			this.playing = true;

		} //

		public function setFrame( frame:int ):void {

			this.currentFrame = frame;
			this._gotoFrame = true;

		} //

		public function handleLabel( label:String, handler:Function, listenOnce:Boolean = true ):void {

			if ( this._labelHandlers == null ) {
				this._labelHandlers = new Vector.<LabelHandler>();
			}

			this._labelHandlers.push( new LabelHandler( label, handler, listenOnce ) );

		} //

		public function removeLabelHandler( handler:Function ):void {

			for ( var i:int = this._labelHandlers.length-1; i >= 0; i-- ) {

				if ( this._labelHandlers[i].handler == handler ) {

					// fast splice.
					this._labelHandlers[i] = this._labelHandlers[ this._labelHandlers.length-1 ];
					this._labelHandlers.pop();

				} //

			} // for-loop.

		} // end removeLabelHandler()

	} // End VariableSpeedTimeline

} // End package