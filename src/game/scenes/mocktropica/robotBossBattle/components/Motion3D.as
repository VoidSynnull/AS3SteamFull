package game.scenes.mocktropica.robotBossBattle.components {

	import flash.geom.Vector3D;
	
	import ash.core.Component;

	public class Motion3D extends Component {

		public var velocity:Vector3D;
		public var acceleration:Vector3D;

		/**
		 * maxSpeed currently not implemented, I think. TEEHEE.
		 */
		public var maxSpeed:Number = 200;
		public var maxAcceleration:Number = 4000;

		public var friction:Number = 0.10;

		public var omega:Number;

		public function Motion3D( vx:Number=0, vy:Number=0, vz:Number=0, omega:Number=0 ) {

			this.velocity = new Vector3D( vx, vy, vz );
			this.acceleration = new Vector3D( 0, 0, 0 );

			this.omega = omega;

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