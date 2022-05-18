package game.scenes.virusHunter.heart.systems {

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.utils.Dictionary;
	
	import engine.ShellApi;
	import engine.components.Display;
	import engine.group.DisplayGroup;
	import engine.util.Command;
	
	import game.components.entity.Parent;
	import game.scenes.virusHunter.heart.classes.ArmExtendJob;
	import game.scenes.virusHunter.heart.components.ArmSegment;
	import game.scenes.virusHunter.heart.components.RigidArm;
	import game.scenes.virusHunter.heart.components.RigidArmExtend;
	import game.scenes.virusHunter.heart.components.RigidArmMode;
	import game.scenes.virusHunter.heart.nodes.ArmExtendNode;
	import game.systems.GameSystem;

	public class ArmExtendSystem extends GameSystem {

		/**
		 * Loading and extending of individual arms is left to job helper classes.
		 */
		private var jobs:Dictionary;

		public function ArmExtendSystem() {

			super( ArmExtendNode, nodeUpdate, nodeAdded, nodeRemoved );

			jobs = new Dictionary( true );

		} //

		public function nodeUpdate( node:ArmExtendNode, time:Number ):void {

			if ( (node.mode.curMode & ( RigidArmMode.EXTEND | RigidArmMode.RETRACT )) == 0 ) {
				return;			// Wrong mode.
			}

			if ( node.mode.curMode & RigidArmMode.EXTEND ) {

				// We can't test if targetSegments > arm.segments.length here because a current job segment
				// might be animating even though its already in arm.segments.
				doExtend( node, time );

			} else if ( node.mode.curMode & RigidArmMode.RETRACT ) {

				doRetract( node, time );

			} // end-if.

		} //

		private function doExtend( node:ArmExtendNode, time:Number ):void {

			var extend:RigidArmExtend = node.extend;
			var arm:RigidArm = node.arm;
			var segment:ArmSegment;

			var job:ArmExtendJob = jobs[ node ];
			if ( job == null ) {
				job = jobs[ node ] = new ArmExtendJob();
			} //

			if ( job.loading ) {
				return;
			}

			if ( job.curSegment != null ) {

				job.timer -= time;
				if ( job.timer <= 0 ) {

					job.curSegment.radius = extend.segmentRadius;			// set to the final radius.
					if ( extend.targetSegments == arm.segments.length ) {
						// NO MORE SEGMENTS TO ADD.
						extend.onExtendComplete.dispatch( node.entity );
					} else if ( extend.targetSegments > arm.segments.length ) {
						loadSegment( node, job );
					}

				} else {

					job.curSegment.radius = ( 1 - (job.timer/extend.extendTime) )*extend.segmentRadius;

				} // end-if.

			} else if ( extend.targetSegments > arm.segments.length ) {

				loadSegment( node, job );

			} // end-if.

		} //

		private function doRetract( node:ArmExtendNode, time:Number ):void {

			var extend:RigidArmExtend = node.extend;
			var arm:RigidArm = node.arm;
			var segment:ArmSegment;

			var job:ArmExtendJob = jobs[ node ];
			if ( job == null ) {
				job = jobs[ node ] = new ArmExtendJob();
			} //
			if ( job.loading ) {			// hope this never happens...
				return;
			}

			if ( job.curSegment != null ) {

				job.timer -= time;
				if ( job.timer <= 0 ) {

					extend.onSegmentRemoved.dispatch( node.entity, job.curSegment );

					arm.shiftSegment();				// remove the first segment.

					if ( node.extend.autoHandleEntities ) {
						this.group.removeEntity( job.curSegment.entity );
					} //

					if ( extend.targetSegments == arm.segments.length ) {

						// NO MORE SEGMENTS TO REMOVE.
						job.curSegment = null;
						extend.onExtendComplete.dispatch( node.entity );

					} else if ( extend.targetSegments < arm.segments.length ) {

						job.curSegment = arm.segments[0];
						job.timer = extend.extendTime;

					} // end-if.

				} else {

					// Shrink the segment radius.
					job.curSegment.radius = (job.timer/extend.extendTime)*extend.segmentRadius;

				} // end-if.
				
			} else if ( extend.targetSegments < arm.segments.length ) {

				job.curSegment = arm.segments[0];
				job.timer = extend.extendTime;

			} // end-if.

		} //

		/**
		 * Load a new arm segment as part of an arm extending.
		 */
		private function loadSegment( node:ArmExtendNode, job:ArmExtendJob ):void {

			// LOAD NEW ARM SEGMENT.
			job.loading = true;
			var g:DisplayGroup = this.group as DisplayGroup;

			g.loadFile( node.extend.segmentFile, segmentLoaded, node );

		} //

		private function segmentLoaded( clip:MovieClip, node:ArmExtendNode ):void {

			if ( clip == null ) {
				return;
			}

			var job:ArmExtendJob = jobs[ node ];
			if ( job == null ) {
				return;
			}

			// Now we need to move the clip to the virus entity's display.
			// this is where all this entity stuff gets really annoying.
			var display:DisplayObjectContainer = ( ( node.entity.get( Parent ) as Parent ).parent.get( Display ) as Display ).displayObject;
			display.addChildAt( clip, 0 );

			var curSegment:ArmSegment = job.curSegment = new ArmSegment( clip );

			node.arm.unshiftSegment( curSegment );

			// The old-first segment will slowly drift apart from the new segment as the radius increases.
			curSegment.radius = 0;							// start at 0, head to extend.segmentRadius

			job.timer = node.extend.extendTime;
			job.loading = false;

			if ( node.extend.autoHandleEntities ) {
				this.group.addEntity( curSegment.entity );
			} //

			node.extend.onSegmentAdded.dispatch( node.entity, curSegment );

		} //

		public function nodeAdded( node:ArmExtendNode ):void {

			// Create a new job to process the node.
			var job:ArmExtendJob = jobs[ node ] = new ArmExtendJob();

			var extend:RigidArmExtend = node.extend;
			var arm:RigidArm = node.arm;

			if ( node.mode.curMode & RigidArmMode.EXTEND ) {
	
				if ( extend.targetSegments > arm.segments.length ) {
					loadSegment( node, job );
				} //

			} else if ( node.mode.curMode & RigidArmMode.RETRACT ) {

				if ( extend.targetSegments < arm.segments.length ) {

					job.curSegment = arm.segments[0];			// select the arm segment that will start contracting.
					job.timer = extend.extendTime;

				} //

			} //

		} // nodeAdded()

		public function nodeRemoved( n:ArmExtendNode ):void {

			/**
			 * In case there are any lingering jobs. If a load is in progress,
			 * the callback will still get called, but we can ignore it there.
			 */
			n.extend.onSegmentAdded.removeAll();
			n.extend.onSegmentRemoved.removeAll();
			n.extend.onExtendComplete.removeAll();

			delete jobs[ n ];

		} //

	} // End ArmExtendSystem

} // End package