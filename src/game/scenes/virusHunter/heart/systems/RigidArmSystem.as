package game.scenes.virusHunter.heart.systems {

	import game.scenes.virusHunter.heart.components.ArmSegment;
	import game.scenes.virusHunter.heart.components.RigidArm;
	import game.scenes.virusHunter.heart.nodes.RigidArmNode;
	import game.systems.GameSystem;

	/**
	 * This runs the forward computation of all the arm positions and rotations.
	 * The IK algorithm is a shoddy "cyclic coordinate descent" in ArmTargetSystem.
	 */
	public class RigidArmSystem extends GameSystem {

		static private const RAD_PER_DEG:Number = Math.PI/180;
		static private const DEG_PER_RAD:Number = 180/Math.PI;

		public function RigidArmSystem() {

			super( RigidArmNode, updateNode, nodeAdded );

		} //

		/**
		 * The spatials are updated here as well, just to save the trouble of a second system.
		 */
		public function updateNode( node:RigidArmNode, time:Number ):void {

			var arm:RigidArm = node.arm;
			var segs:Vector.<ArmSegment> = arm.segments;

			var cur:ArmSegment;
			var prev:ArmSegment = segs[0];
			var tx:Number = prev.x;
			var ty:Number = prev.y;

			prev.theta += prev.omega*time;

			// running total of arm rotations so the absolute theta can be set for each segment.
			var thetaTotal:Number = prev.theta;
			prev.spatial.x = prev.x;
			prev.spatial.y = prev.y;
			prev.spatial.rotation = thetaTotal*DEG_PER_RAD;

			var len:int = segs.length-1;
			for( var i:int = 1; i <= len; i++ ) {

				cur = segs[i];

				if ( arm.followParents ) {
					cur.omega += 10*( prev.omega - cur.omega )*time;
				} // end-if.

				cur.theta += cur.omega*time;
				if ( cur.theta > cur.maxTheta ) {
					cur.theta = cur.maxTheta;
				} else if ( cur.theta < -cur.maxTheta ) {
					cur.theta = -cur.maxTheta;
				} // end-if.

				// Update current segment position. tx,ty tracks the total position so far.
				cur.spatial.x = cur.x = tx += prev.radius*Math.cos( thetaTotal );
				cur.spatial.y = cur.y = ty += prev.radius*Math.sin( thetaTotal ); 

				// Similar for thetaTotal.
				cur.absTheta = thetaTotal += cur.theta;

				cur.spatial.rotation = thetaTotal*DEG_PER_RAD;

				prev = cur;

			} // end-for.

			/**
			 * Important for later algorithimns which need to know the end position of the arm
			 * for targetting.
			 */
			arm.endX = tx + prev.radius*Math.cos( thetaTotal );
			arm.endY = ty + prev.radius*Math.sin( thetaTotal );

		} // updateNode

		public function nodeAdded( node:RigidArmNode ):void {

			// Get the end position and intermediate angles computed.
			updateNode( node, 0 );

		} //

	} // End RigidArmSystem

} // End package