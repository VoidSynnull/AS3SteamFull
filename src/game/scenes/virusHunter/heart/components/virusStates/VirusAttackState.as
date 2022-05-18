package game.scenes.virusHunter.heart.components.virusStates {

	import ash.core.Entity;
	
	import game.scenes.virusHunter.heart.components.RigidArmMode;

	/**
	 * In this state the virus will target its arms on the player and then return them to normal.
	 */
	public class VirusAttackState extends QuadVirusState {

		static private const ATTACKING:int = 2;
		static private const RESTORE:int = 3;			// restoring virus position to starting angle.

		// time between attacks.
		private var timer:Number;

		private var phase:int;

		public function VirusAttackState( virus:Entity ) {

			super( virus );

		} //

		override public function start():void {

			doAttack();

		} //

		override public function update( time:Number ):void {

			timer += time;

			if ( phase == ATTACKING ) {

				if ( timer > 4 ) {
					attackDone();
				} //

			} else {

				if ( timer > 1 ) {
					restoreDone();
				}

			} //

		} // update()

		public function doAttack():void {

			phase = ATTACKING;

			timer = 0;
			this.quadVirus.targetPlayer();

		} //

		private function attackDone():void {

			// set all the arm modes to...
			this.quadVirus.setArmMode( RigidArmMode.RESTORE );
			phase = RESTORE;
			timer = 0;

		} // attackDone()

		private function restoreDone():void {

			if ( onStateDone != null ) {
				onStateDone( this );
			}

		} // restoreDone()

	} // End class

} // End package