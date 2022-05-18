package game.scenes.virusHunter.heart.components.virusStates {
	
	import ash.core.Entity;
	
	import game.scenes.virusHunter.heart.components.RigidArmMode;
	import game.scenes.virusHunter.heart.components.virusActions.SwingAttack;

	public class VirusSwingState extends QuadVirusState {

		static private const SWINGING:int = 2;
		static private const RESTORE:int = 3;			// restoring virus position to starting angle.

		private var phase:int;

		private var swingAttack:SwingAttack;

		private var startAngle:Number;

		public function VirusSwingState( virus:Entity ) {

			super( virus );

			swingAttack = new SwingAttack( virus );
			swingAttack.setPeriod( 1 );

			startAngle = spatial.rotation;

		} //

		override public function start():void {

			doSwing();

		} //

		override public function update( time:Number ):void {

			if ( phase == SWINGING ) {
	
				swingAttack.update( time );

			} else {

				restoring();

			} //

		} //

		public function doSwing():void {

			quadVirus.waveArms();

			phase = SWINGING;
			swingAttack.start( swingDone );

		} //

		private function swingDone():void {

			quadVirus.endArmWave();
			quadVirus.setArmMode( RigidArmMode.RESTORE );

			phase = RESTORE;
			var dtheta:Number = startAngle - spatial.rotation;

			if ( dtheta > 180 ) {
				dtheta -= 360;
			} else if ( dtheta < -180 ) {
				dtheta += 360;
			}

			if ( Math.abs( dtheta ) < 1 ) {
				restoreDone();
			} else {
				motion.rotationAcceleration = 0;
				motion.rotationVelocity += ( dtheta - motion.rotationVelocity ) / 2;
			}

		} //

		private function restoring():void {

			var dtheta:Number = startAngle - spatial.rotation;
			if ( dtheta > 180 ) {
				dtheta -= 360;
			} else if ( dtheta < -180 ) {
				dtheta += 360;
			}

			if ( Math.abs( dtheta ) < 1 ) {

				restoreDone();

			} else {

				motion.rotationVelocity += ( dtheta - motion.rotationVelocity ) / 2;

			} //

		} //

		private function restoreDone():void {

			motion.rotationVelocity = 0;
			motion.rotationAcceleration = 0;

			spatial.rotation = startAngle;

			if ( onStateDone != null ) {
				onStateDone( this );
			}

		} //

	} // End class

} // End package