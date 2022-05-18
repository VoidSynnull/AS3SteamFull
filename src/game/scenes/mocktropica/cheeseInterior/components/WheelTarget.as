package game.scenes.mocktropica.cheeseInterior.components {

	import ash.core.Entity;
	
	import ash.core.Component;
	
	import org.osflash.signals.Signal;

	public class WheelTarget extends Component {

		/**
		 * Angle target will take precedence over omega target.
		 */
		public var useAngleTarget:Boolean = false;
		public var useOmegaTarget:Boolean = false;

		/**
		 * Angle from target where the wheel will begin to slow down.
		 */
		public var slowRadius:Number = 10*Math.PI/180;

		/**
		 * Angle from target where wheel will stop.
		 */
		public var stopRadius:Number = 2*Math.PI/180;

		public var angle:Number;
		public var omega:Number;

		/**
		 * Signal returns: onTargetDone( entity, wheelTarget );
		 */
		public var onTargetDone:Signal;

		public function WheelTarget() {

			this.onTargetDone = new Signal( Entity, WheelTarget );

		} //

		public function setTargetAngle( target:Number ):void {

			this.angle = target;

			this.useAngleTarget = true;
			this.useOmegaTarget = false;		// so it won't revert automatically when done.

		} //

		public function setTargetOmega( target:Number ):void {

			this.omega = target;
			this.useOmegaTarget = true;
			this.useAngleTarget = false;

		} //

	} // End WheelTarget

} // End package