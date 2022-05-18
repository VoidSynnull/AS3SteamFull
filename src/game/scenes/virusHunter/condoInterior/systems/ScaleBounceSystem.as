package game.scenes.virusHunter.condoInterior.systems {

	import game.scenes.virusHunter.condoInterior.components.ScaleBounce;
	import game.scenes.virusHunter.condoInterior.nodes.ScaleBounceNode;
	import game.systems.GameSystem;

	// This system just scales an item up and bounces it a bit.

	public class ScaleBounceSystem extends GameSystem {

		public function ScaleBounceSystem():void {

			super( ScaleBounceNode, updateNode, nodeAdded, null );

		} //

		private function updateNode( node:ScaleBounceNode, time:Number ):void {

			var bounce:ScaleBounce = node.bounce;

			if ( bounce.enabled == false ) {
				return;
			}

			/**
			 * Experiments with a separate file have shown that if the time is greater than this value (forcing ax below > 1 ),
			 * then the verlet integration will diverge and go wild.
			 */
			if ( time > 0.017 ) {
				time = 0.017;
			} //

			var cur:Number = bounce.curScale;

			if ( Math.abs( cur - bounce.lastScale ) < bounce.minDeltaScale && Math.abs( cur - bounce.targetScale ) < bounce.minDeltaScale ) {

				bounce.curScale = bounce.targetScale;
				bounce.enabled = false;

				if ( bounce.onScaleDone != null ) {
					bounce.onScaleDone( node.entity );
				}

				return;

			} // end-if.

			// factored out one of the time variables for efficiency. lastTime is for nonconstant time correction.
			var ax:Number = bounce.spring*( bounce.targetScale - cur );

			bounce.curScale = (2-bounce.damping)*cur - (1-bounce.damping)*bounce.lastScale + ax*time*time;
			bounce.lastScale = cur;

			node.spatial.scaleX = node.spatial.scaleY = bounce.curScale;

		} //

		private function nodeAdded( node:ScaleBounceNode ):void {

			node.bounce.curScale = node.bounce.lastScale = node.spatial.scaleX;

		} //

		/*private function nodeRemoved( node:ScaleBounceNode ):void {
		} //*/

	} // End class

} // End package