package game.scenes.mocktropica.cheeseInterior.systems {

	import flash.display.MovieClip;
	
	import ash.core.Engine;
	import ash.core.Entity;

	import game.data.animation.LabelHandler;
	import game.components.entity.VariableTimeline;
	import game.scenes.mocktropica.cheeseInterior.nodes.VariableTimelineNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	import org.osflash.signals.Signal;

	/**
	 * This is just a timeline system that allows you to control the rate/speed at which the timeline advances.
	 * I imagine the regular timeline will have this functionality added at some point, but it doesn't
	 * have it yet, and I need it now.
	 */
	public class VariableTimelineSystem extends GameSystem {

		/**
		 * Animation rate in Seconds-per-frame.
		 */
		private const BASE_FRAME_RATE:Number = 1/32;

		public function VariableTimelineSystem() {

			super( VariableTimelineNode, this.updateNode, this.nodeAdded, this.nodeRemoved );

			super._defaultPriority = SystemPriorities.timelineControl;

		} //

		override public function addToEngine( e:Engine ):void {

			super.addToEngine( e );

		} //

		private function updateNode( node:VariableTimelineNode, time:Number ):void {

			var tl:VariableTimeline = node.timeline;
			var mc:MovieClip = node.display.displayObject as MovieClip;

			if ( tl._gotoFrame != null ) {

				mc.gotoAndStop( tl._gotoFrame );
				tl.currentFrame = mc.currentFrame;
				tl._gotoFrame = null;

				if ( mc.currentFrameLabel != null ) {
					this.dispatchLabel( node, tl, mc.currentFrameLabel );
				}

				// the current frame was manually changed, so no frame-playing updates go through until next time.

			} else {

				if ( tl.playing == false ) {
					return;
				} //

				tl._accumulator += time * tl.rate;
				while ( tl._accumulator >= this.BASE_FRAME_RATE ) {

					tl._accumulator -= this.BASE_FRAME_RATE;
					this.advanceTimeline( node, tl );

					if ( mc.currentFrameLabel != null ) {
						this.dispatchLabel( node, tl, mc.currentFrameLabel );
					}

					if ( !tl.playing ) {		// events within the loop could cause play to stop.
						break;
					}

				} // end frame-advance.

			} //

		} //

		/**
		 * Todo: find a more logical method for advancing the movieclip playhead.
		 */
		private function advanceTimeline( node:VariableTimelineNode, tl:VariableTimeline ):void {

			if ( tl.reverse == false ) {

				++tl.currentFrame;
				if ( tl.currentFrame == tl.maxFrames ) {

					if ( !tl.loop ) {
						//trace( "playing stop " );
						tl.playing = false;
					} //
					// make sure to have the correct frame before dispatch.
					( node.display.displayObject as MovieClip ).gotoAndStop( tl.currentFrame );
					tl.onTimelineEnd.dispatch( node.entity, tl );

				} else if ( tl.currentFrame > tl.maxFrames ) {

					tl.currentFrame = 0;
					( node.display.displayObject as MovieClip ).gotoAndStop( tl.currentFrame );
					//trace( "CURRENT: " + tl.currentFrame );

				} else {
					( node.display.displayObject as MovieClip ).gotoAndStop( tl.currentFrame );
				}//

			} else {

				--tl.currentFrame;
				if ( tl.currentFrame == 0 ) {

					if ( !tl.loop ) {
						tl.playing = false;
					} //
					// make sure to have the correct frame before dispatch.
					( node.display.displayObject as MovieClip ).gotoAndStop( tl.currentFrame );
					tl.onTimelineEnd.dispatch( node.entity, tl );

				} else if ( tl.currentFrame < 0 ) {

					tl.currentFrame = tl.maxFrames;
					( node.display.displayObject as MovieClip ).gotoAndStop( tl.currentFrame );

				} else {
					( node.display.displayObject as MovieClip ).gotoAndStop( tl.currentFrame );
				}

			} //

		} // advanceTimeline()

		private function dispatchLabel( node:VariableTimelineNode, tl:VariableTimeline, label:String ):void {

			tl.onLabelReached.dispatch( node.entity, label );

			var handlers:Vector.<LabelHandler> = tl._labelHandlers;
			if ( handlers == null ) {
				return;
			}

			for( var i:int = handlers.length-1; i >= 0; i-- ) {

				if ( handlers[i].label == label ) {

					handlers[i].handler( node.entity, tl );

					// check for removing handler.
					if ( handlers[i].listenOnce ) {
						handlers[i] = handlers[ handlers.length-1 ];
						handlers.pop();
					}

				} //

			} // end for-loop.

		} //

		private function nodeAdded( node:VariableTimelineNode ):void {

			node.timeline._accumulator = 0;
			node.timeline.maxFrames = ( node.display.displayObject as MovieClip ).totalFrames;

			( node.display.displayObject as MovieClip ).stop();

			if ( node.timeline.onTimelineEnd == null ) {
				node.timeline.onTimelineEnd = new Signal( Entity, VariableTimeline );
			} //

		} //

		private function nodeRemoved( node:VariableTimelineNode ):void {

			node.timeline.onLabelReached.removeAll();
			node.timeline._labelHandlers = null;
			node.timeline.onTimelineEnd.removeAll();

		} //

		/*override public function removeFromEngine( engine:Engine ):void {

			super.removeFromEngine( engine );

		} //*/

	} // End class

} // End package