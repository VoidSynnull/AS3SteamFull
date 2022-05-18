package game.scenes.virusHunter.heart.components.virusActions {

	import ash.core.Entity;

	public class SwingAttack extends VirusAction {

		// Rotation when action was started.
		protected var baseRotate:Number;

		// Maximum rotation from baseRotate. Won't be strictly enforced, but used to calculate starting
		// velocities.
		protected var maxRotate:Number = 24;

		public var springConst:Number = 0.1;

		public var numSwings:Number = 1.25;

		public var period:Number;

		public function SwingAttack( virus:Entity ) {

			super( virus );

			baseRotate = spatial.rotation;

			period = 2*Math.PI*Math.sqrt( 1 / springConst );

		} //

		/**
		 * Need to calculate the estimated angularVelocity (omega) we'd have at the given starting angle.
		 * Using the starting rotation as the base angle simplifies this calculation.
		 * The exact value is: ( (k/m)*( (ThetaMax - ThetaBase)^2 - (ThetaCur - ThetaBase)^2 ) )^(1/2)
		 * Here, m represents mass in the spring equation (in this case moment of intertia) and is not used by
		 * the system, so we assume m=1.
		 */
		override public function start( doneFunc:Function=null ):void {

			super.start( doneFunc );

			baseRotate = spatial.rotation;

			var dtheta:Number = spatial.rotation - baseRotate;
			if ( dtheta > 180 ) {
				dtheta -= 360;
			} else if ( dtheta < -180 ) {
				dtheta += 360;
			} //

			// At least attempt to keep the same DIRECTION as the current angular velocity, so there's as little jarring
			// as possible.
			if ( motion.rotationVelocity >= 0 ) {
				motion.rotationVelocity = Math.sqrt( springConst )*( maxRotate );
			} else {
				motion.rotationVelocity = -Math.sqrt( springConst )*( maxRotate );
			} //

			timer = 0;

		} //

		public function setPeriod( period:Number ):void {

			this.period = period;

			springConst = ( 2*Math.PI ) / period;
			springConst *= springConst;

		} //

		override public function update( time:Number ):void {

			timer += time;

			if ( timer > numSwings*period ) {

				// done.
				onActionDone();

			} else {

				var dtheta:Number = baseRotate - spatial.rotation;
				if ( dtheta > 180 ) {
					dtheta -= 360;
				} else if ( dtheta < -180 ) {
					dtheta += 360;
				} //

				motion.rotationVelocity += springConst*dtheta*time;

			} //

		} //

	} // End class

} // End package