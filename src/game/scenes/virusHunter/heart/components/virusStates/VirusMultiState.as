package game.scenes.virusHunter.heart.components.virusStates {

	import ash.core.Entity;

	/**
	 * Switches between a several different states.
	 */
	public class VirusMultiState extends QuadVirusState {

		private var states:Vector.<QuadVirusState>;

		private var curIndex:int;
		private var curState:QuadVirusState;

		// Time to wait between the different states.
		private var waiting:Boolean = false;
		private var timer:Number;
		public var waitTime:Number = 2.5;

		public function VirusMultiState( virus:Entity, states:Vector.<QuadVirusState> ) {

			super( virus );

			for( var i:int = states.length-1; i >= 0; i-- ) {

				states[i].onStateDone = subStateDone;

			} //

			this.states = states;

			this.curIndex = 0;
			this.curState = states[curIndex];

			this.timer = this.waitTime;
			this.waiting = true;

		} // VirusMultiState()

		override public function update( time:Number ):void {

			if ( waiting ) {

				timer -= time;
				if ( timer <= 0 ) {

					waiting = false;
					this.curState.start();
				}

			} else {

				this.curState.update( time );

			}

		} //

		public function subStateDone( oldState:QuadVirusState ):void {

			this.curIndex++;
			if ( this.curIndex >= this.states.length ) {
				this.curIndex = 0;
			}
			this.curState = this.states[ this.curIndex ];

			this.waiting = true;
			this.timer = waitTime;

			quadVirus.waveArms();

		} //

	} // End class

} // End package