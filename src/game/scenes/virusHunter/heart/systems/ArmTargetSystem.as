package game.scenes.virusHunter.heart.systems {

	import game.scenes.virusHunter.heart.components.ArmSegment;
	import game.scenes.virusHunter.heart.components.RigidArm;
	import game.scenes.virusHunter.heart.components.RigidArmMode;
	import game.scenes.virusHunter.heart.nodes.ArmTargetNode;
	import game.systems.GameSystem;

	/**
	 * Using a rather inexact method of inverse kinematics visa vis:
	 * http://graphics.cs.cmu.edu/nsp/course/15-464/Spring11/afs/asst2%20handout/jlander_gamedev_nov98.pdf
	 */
	public class ArmTargetSystem extends GameSystem {

		/**
		 * Square of minimum distance to target that will be considered acceptable to the algorithm.
		 */
		static private const MIN_DIST_SQUARED:Number = 20;

		public function ArmTargetSystem() {

			super( ArmTargetNode, updateNode, nodeAddedFunction );

		} //

		/**
		 * By this point, arm.endX,endY must already have been computed by the RigidArmSystem
		 * 
		 * For all the fanfare, all this function does is get the angle at a current segment
		 * between the end of the arm and the target, and rotate according to that angle.
		 */
		public function updateNode( node:ArmTargetNode, time:Number ):void {

			if ( (node.mode.curMode & RigidArmMode.TARGET) == 0 ) {
				return;
			} //

			var arm:RigidArm = node.arm;
			var segs:Vector.<ArmSegment> = arm.segments;

			var segment:ArmSegment;
			var endX:Number = arm.endX;
			var endY:Number = arm.endY;
			var targetX:Number = node.target.targetX;
			var targetY:Number = node.target.targetY;

			if ( isNaN(targetX) || isNaN(targetY) ) {
				// This should not happen.
				return;
			}
			if ( isNaN(endX) || isNaN(endY ) ) {
				// This should not happen.
				return;
			}

			// dx,dy is vector from current segment to end of the arm. (endX,endY)
			var dx:Number, dy:Number;
			var tx:Number; //= targetX - arm.startX;			// vector from current segment to target.
			var ty:Number; //= targetY - arm.startY;

			/*// a quick check to cancel the target if it's too far away.
			if ( Math.sqrt(tx*tx + ty*ty) > 400 ) {
				restore( segs, time );
				return;
			} //*/

			// computation numbers.
			var cross:Number, dtheta:Number;

			for( var i:int = segs.length-1; i >= 0; i-- ) {

				segment = segs[ i ];

				dx = endX - segment.x;
				dy = endY - segment.y;

				tx = targetX - segment.x;
				ty = targetY - segment.y;

				cross = ( dx*ty - dy*tx ) / Math.sqrt( (dx*dx+dy*dy)*(tx*tx+ty*ty) );
				// Because the cross product is divided by the lengths of the two cross-vectors, arcsine should always exist.
				dtheta = Math.asin( cross )*time;

				segment.omega = 0;
				segment.theta += dtheta;
				segment.absTheta += dtheta;

				// Update endx,endy for the rotation that was just applied to the arm.
				// This computation is surprisingly accurate. see computeEnd() below.
				endX = segment.x + dx*Math.cos( dtheta ) - dy*Math.sin( dtheta );
				endY = segment.y + dx*Math.sin( dtheta ) + dy*Math.cos( dtheta );

				// this little bit computes the distance from the end to the target.
				dx = targetX - endX;
				dy = targetY - endY;
				if ( dx*dx + dy*dy < MIN_DIST_SQUARED ) {
					break;
				}

			} // end-while.

		} // updateNode()

		public function restore( segs:Vector.<ArmSegment>, time:Number ):void {

			var seg:ArmSegment;
			var dtheta:Number;
			for( var i:int = segs.length-1; i >= 0; i-- ) {
				
				seg = segs[ i ];
				dtheta = seg.baseTheta - seg.theta;
				if ( dtheta > Math.PI ) {
					dtheta -= 2*Math.PI;
				} else if ( dtheta < -Math.PI ) {
					dtheta += 2*Math.PI;
				}
				
				seg.theta += dtheta*time;
				seg.omega *= 0.9;
				
			} //

		} //

		/*private function computeEnd( start:int, segments:Vector.<ArmSegment>, p:Point ):void {

			var prev:ArmSegment = segments[start];

			var tx:Number = prev.x;
			var ty:Number = prev.y;

			var absTheta:Number = prev.absTheta;

			var cur:ArmSegment;
			for( var i:int = start+1; i < segments.length; i++ ) {

				cur = segments[i];

				tx += prev.radius*Math.cos( absTheta );
				ty += prev.radius*Math.sin( absTheta );

				absTheta += cur.theta;
				prev = cur;

			} //

			p.x = tx + prev.radius*Math.cos( absTheta );
			p.y = ty + prev.radius*Math.sin( absTheta );

		} //*/

		public function nodeAdded( node:ArmTargetNode ):void {
		} //

	} // End ArmTargetSystem

} // End package