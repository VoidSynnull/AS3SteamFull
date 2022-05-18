package game.scenes.carnival.shared.game3d.components {

	import flash.geom.Vector3D;
	
	import ash.core.Component;

	public class Motion3D extends Component {

		public var velocity:Vector3D;
		public var acceleration:Vector3D;

		public var maxSpeed:Number = 200;
		public var maxAcceleration:Number = 100;

		/**
		 * velocity -= drag*velocity*time, every frame.
		 */
		public var drag:Number = 0.10;

		public function Motion3D( vx:Number=0, vy:Number=0, vz:Number=0 ) {

			this.velocity = new Vector3D( vx, vy, vz );
			this.acceleration = new Vector3D( 0, 0, 0 );

		} //

		public function zeroMotion():void {

			this.velocity.setTo( 0, 0, 0 );

		} //

		public function setVelocity( vx:Number, vy:Number, vz:Number ):void {

			this.velocity.x = vx;
			this.velocity.y = vy;
			this.velocity.z = vz;

		} //

	} // End SimpleMotion

} // End package