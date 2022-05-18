package game.scenes.mocktropica.cheeseInterior.components {

	import ash.core.Entity;
	
	import ash.core.Component;
	
	import org.osflash.signals.Signal;
	
	public class Wheel extends Component {

		public const RAD_PER_DEG:Number = Math.PI / 180;
		public const DEG_PER_RAD:Number = 180 / Math.PI;

		public var maxAcceleration:Number = 100*Math.PI/180;

		public var omega:Number;

		/**
		 * Minimum turning speed before wheel stops automatically.
		 */
		public var minOmega:Number = 1*Math.PI/180;

		/**
		 * Since maxOmega is per second, not per frame, it can be much larger than 2*pi
		 */
		public var maxOmega:Number = 4*Math.PI;

		public var drag:Number;

		public var angle:Number;

		/**
		 * onWheelStop( Entity, Wheel );
		 */
		public var onWheelStop:Signal;

		public function Wheel( curAngle:Number=0, curDrag:Number=1 ) {

			this.onWheelStop = new Signal( Entity, Wheel );

			this.angle = curAngle;
			this.omega = 0;
			this.drag = curDrag;

		} //

	} // End Wheel

} // End package