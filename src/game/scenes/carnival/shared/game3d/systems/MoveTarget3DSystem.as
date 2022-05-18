package game.scenes.carnival.shared.game3d.systems {

	import game.scenes.mocktropica.robotBossBattle.components.Motion3D;
	import game.scenes.mocktropica.robotBossBattle.components.MoveTarget3D;
	import game.scenes.mocktropica.robotBossBattle.nodes.MoveTarget3DNode;
	import game.systems.GameSystem;

	public class MoveTarget3DSystem extends GameSystem {

		public function MoveTarget3DSystem() {

			super( MoveTarget3DNode, this.updateNode, this.nodeAdded, null );

		} //

		/**
		 * Setting the intended or 'steered' direction should actually be separate from
		 * the acceleration which actually occurs in motion. Would be a bit slower, and
		 * there's no time for that now.
		 */
		public function updateNode( node:MoveTarget3DNode, time:Number ):void {

			var target:MoveTarget3D = node.target;
			if ( !target.active ) {
				return;
			}

			var dx:Number = target.x - node.spatial.x;
			var dy:Number = target.y - node.spatial.y;
			var dz:Number = target.z - node.zdepth.z;

			var d:Number = Math.sqrt( dx*dx + dy*dy + dz*dz );

			var motion:Motion3D = node.motion;

			if ( d < target.stopRadius ) {
			//	trace( "TARGET Y: " + target.y + "  SPATIAL Y: " + node.spatial.y );
				target.onReachedTarget.dispatch( node.entity );
				return;
			} 

			var targetSpeed:Number;
			if ( d < target.slowRadius ) {

				// there are some factors of 'd' in here but they cancel out.
				targetSpeed = motion.maxSpeed / target.slowRadius;

			} else {

				// the 'd' will occur in every x,y,z factor, so it might as well be included here.
				targetSpeed = motion.maxSpeed / d;

			} // end-if.

			// a division of a time-acceleration interval can be included here. 2 sec, for example.
			// it's probably not important since maxAcceleration sets the upper limit.
			motion.acceleration.x = dx*targetSpeed - motion.velocity.x;
			motion.acceleration.y = dy*targetSpeed - motion.velocity.y;
			motion.acceleration.z = dz*targetSpeed - motion.velocity.z;

			d = motion.acceleration.length;
			if ( d > motion.maxAcceleration ) {
				motion.acceleration.scaleBy( motion.maxAcceleration / d );
			}

		} // updateNode()

		private function nodeAdded( node:MoveTarget3DNode ):void {
		} //

		/**
		private function nodeRemoved( node:MoveTargetNode ):void {
		} //
		 * */

	} // End MoveTargetSystem
	
} // End package