package game.scenes.carnival.shared.ferrisWheel.components {

	import ash.core.Entity;
	
	import ash.core.Component;
	
	import org.osflash.signals.Signal;

	/**
	 * Angles in this class are measured in degrees, to match the motion component.
	 */
	public class RotationTarget extends Component {

		public var enabled:Boolean = false;
		
		/**
		 * If true, targets a specific angular velocity.
		 * If false, targets a specific angle of rotation.
		 */
		public var useVelocityTarget:Boolean = true;
		
		/**
		 * If auto-remove is true, component will be removed once angular velocity
		 * reaches its target.
		 */
		public var autoRemove:Boolean = false;
		
		/**
		 * If auto-disble is true, component will be disabled once the angular velocity or
		 * angle target is reached.
		 */
		public var autoDisable:Boolean = true;

		public var maxAngularAcceleration:Number = 90;

		/**
		 * Target rotation velocity when useVelocityTarget=true
		 */
		public var rotationVelocity:Number = 0;

		/**
		 * Angle to rotate towards. Used if useVelocityTarget=false.
		 */
		public var rotation:Number = 0;

		/**
		 * Degrees within target angle to stop at.
		 */
		public var stopRadius:Number = 4;

		/**
		 * onReachedTarget( rotatingEntity )
		 */
		public var onReachedTarget:Signal;

		public function RotationTarget() {

			super();

			this.onReachedTarget = new Signal( Entity );

		} //

		public function rotateTo( angle:Number, callback:Function=null ):void {

			this.rotation = angle;
			this.useVelocityTarget = false;
			this.enabled = true;

			if ( callback ) {
				this.onReachedTarget.addOnce( callback );
			}

		} //

		public function rotationVelocityTo( angularVelocity:Number ):void {

			this.rotationVelocity = angularVelocity;
			this.useVelocityTarget = true;
			this.enabled = true;

		} //


	} // End

} // End package