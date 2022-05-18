package game.scenes.virusHunter.heart.systems {

	import game.scenes.virusHunter.heart.components.ArmSegment;
	import game.scenes.virusHunter.heart.components.RigidArmMode;
	import game.scenes.virusHunter.heart.nodes.RigidArmNode;
	import game.systems.GameSystem;

	public class ArmRestoreSystem extends GameSystem {

		public function ArmRestoreSystem() {

			super( RigidArmNode, nodeUpdate, null, null );

		} //

		public function nodeUpdate( node:RigidArmNode, time:Number ):void {

			if ( (node.mode.curMode & RigidArmMode.RESTORE) == 0 ) {
				return;			// Wrong mode.
			}

			var segs:Vector.<ArmSegment> = node.arm.segments;
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

		} // nodeUpdate()

		public function nodeAdded( node:RigidArmNode ):void {
		} // nodeAdded()

	} // End ArmExtendSystem

} // End package