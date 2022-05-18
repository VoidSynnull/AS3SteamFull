package game.scenes.virusHunter.heart.components.virusStates {
	
	import ash.core.Entity;
	
	import game.scenes.virusHunter.heart.components.virusActions.LungeAttack;

	public class VirusLungeState extends QuadVirusState {

		static private const forwardPct:Number = 0.9;
		static private const backwardPct:Number = 0.5;

		static private const forwardTime:Number = 1;
		static private const backwardTime:Number = 2;

		private var startX:Number;
		private var startY:Number;

		private var lunge:LungeAttack;

		public function VirusLungeState( virus:Entity ) {

			super( virus );

			lunge = new LungeAttack( virus );

			startX = spatial.x;
			startY = spatial.y;

		} //

		override public function start():void {
			
			doForwards();

		} //

		override public function update( time:Number ):void {

			lunge.update( time );
	
		} //

		public function doForwards():void {

			quadVirus.targetPlayer();

			lunge.configure( spatial.rotation, 220, 0.6, forwardPct );
			lunge.start( forwardsDone );

			//lunge.onActionDone = forwardsDone;

		} //

		public function doBackwards():void {

			quadVirus.restoreArms();

			lunge.configure( spatial.rotation-180, 220, 2, backwardPct );

			lunge.start( backwardsDone );

		} //

		private function forwardsDone():void {

			doBackwards();

		} //

		private function backwardsDone():void {

			spatial.x = startX;
			spatial.y = startY;

			if ( onStateDone != null ) {
				onStateDone( this );
			}

		} //

	} // End class

} // End package