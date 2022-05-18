package game.scenes.mocktropica.cheeseInterior.systems {

	import ash.core.Engine;
	
	import game.scenes.mocktropica.cheeseInterior.components.Wheel;
	import game.scenes.mocktropica.cheeseInterior.components.WheelTarget;
	import game.scenes.mocktropica.cheeseInterior.nodes.WheelTargetNode;
	import game.systems.GameSystem;

	/**
	 * Because the exact time displayed isn't very important, not bothering to work
	 * through the date object. 
	 */
	public class WheelTargetSystem extends GameSystem {

		public function WheelTargetSystem() {

			super( WheelTargetNode, this.updateNode, this.nodeAdded, this.nodeRemoved );

		} //

		override public function addToEngine( e:Engine ):void {

			super.addToEngine( e );

		} //

		private function updateNode( node:WheelTargetNode, time:Number ):void {

			if ( node.target.useAngleTarget ) {

				this.targetAngle( node, time );

			} else if ( node.target.useOmegaTarget ) {

				this.targetOmega( node, time );

			} //

		} //

		private function targetAngle( node:WheelTargetNode, time:Number ):void {

			var wheel:Wheel = node.wheel;
			var target:WheelTarget = node.target;

			var delta:Number = target.angle - wheel.angle;
			if ( delta > Math.PI ) {
				delta -= Math.PI;
			} else if ( delta < -Math.PI ) {
				delta += Math.PI;
			} //

			if ( Math.abs( delta ) < target.stopRadius ) {

				// this ensures the wheelUpdate will stop the wheel and send the onStopped signal.
				wheel.omega = 0;
				target.useAngleTarget = false;

				// Dispatch the signal.
				target.onTargetDone.dispatch( node.entity, target );

			} else if ( Math.abs( delta ) < target.slowRadius ) {

				var targetSpeed:Number = ( delta / target.slowRadius )*wheel.maxOmega;
				delta = targetSpeed - wheel.omega;
				var accel:Number = wheel.maxAcceleration*time;

				if ( Math.abs(delta) < accel ) {
					wheel.omega = targetSpeed;
				} else {

					if ( delta > 0 ) {
						wheel.omega += accel;
					} else {
						wheel.omega -= accel;
					}

				} //

			} else {

				if ( delta > 0 ) {
					wheel.omega += wheel.maxAcceleration*time;
				} else {
					wheel.omega -= wheel.maxAcceleration*time;
				} //

			} //

		} //

		private function targetOmega( node:WheelTargetNode, time:Number ):void {

			var wheel:Wheel = node.wheel;
			var target:WheelTarget = node.target;
			
			var delta:Number = wheel.omega - target.omega;
			var accel:Number = wheel.maxAcceleration*time;

			if ( Math.abs(delta) < accel ) {

				wheel.omega = target.omega;
				target.useOmegaTarget = false;		// No longer targeting.

				// Dispatch the signal.
				target.onTargetDone.dispatch( node.entity, target );

			} else {

				if ( delta > 0 ) {
					wheel.omega += accel;
				} else {
					wheel.omega -= accel;
				}

			} //

		} //

		private function nodeAdded( node:WheelTargetNode ):void {
		} //

		private function nodeRemoved( node:WheelTargetNode ):void {
		} //

		/*override public function removeFromEngine( engine:Engine ):void {

			super.removeFromEngine( engine );

		} //*/

	} // End class

} // End package