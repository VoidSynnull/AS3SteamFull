package game.scenes.virusHunter.heart.systems {

	import game.scenes.virusHunter.heart.components.ArmSegment;
	import game.scenes.virusHunter.heart.components.ArmWave;
	import game.scenes.virusHunter.heart.nodes.ArmWaveNode;
	import game.systems.GameSystem;

	/**
	 * There's some question whether to apply the wave to the first child segment or the
	 * arm motion itself. I applied it to the child segment.
	 */
	public class ArmWaveSystem extends GameSystem {

		public function ArmWaveSystem():void {

			super( ArmWaveNode, updateNode, nodeAdded, null );

		} //

		private function updateNode( node:ArmWaveNode, time:Number ):void {

			var wave:ArmWave = node.wave;

			var segment:ArmSegment = node.arm.segments[0];
			segment.omega += ( wave.baseTheta - segment.theta )*wave.springConst*time;

			//trace( "omg: " + (180*segment.omega/Math.PI) );

		} //

		private function nodeAdded( node:ArmWaveNode ):void {

			var wave:ArmWave = node.wave;
			var segment:ArmSegment = node.arm.segments[0];
			wave.baseTheta = segment.baseTheta;

			var dtheta:Number = wave.baseTheta - segment.theta;

			// [ (k)*( (ThetaMax - ThetaBase)^2 - (ThetaCur - ThetaBase)^2 ) ]^(1/2)

			dtheta *= dtheta;
			var amp:Number = wave.amplitude*wave.amplitude;

			if ( dtheta > amp ) {

				// segment is further away than the expected maximal distance.
				// segment omega should be 0.. but to avoid abrupt change...
				segment.omega = 0;

			} else if ( segment.omega >= 0 ) {
				segment.omega = Math.sqrt( wave.springConst*( amp - dtheta ) );
			} else {
				segment.omega = -Math.sqrt( wave.springConst*( amp - dtheta ) );
			} //

		} // nodeAdded()

	} // End class

} // End package