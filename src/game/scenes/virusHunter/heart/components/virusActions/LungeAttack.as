package game.scenes.virusHunter.heart.components.virusActions {
	
	import ash.core.Entity;

	/**
	 * Small explanation of acceleration calculations: The virus accelerates for a certain percentage
	 * of the lunge, and then decelerates for the remainder. The values are chosen so that the virus starts and ends
	 * with 0 velocity.
	 */
	public class LungeAttack extends VirusAction {

		public var lungeDistance:Number = 200;

		// Time spent on forward portion of lunge.
		public var lungeTime:Number = 1;

		public var midPercent:Number = 0.8;

		// time to spend in this particular phase of the lunge.
		private var phaseTime:Number;

		public var cos:Number;
		public var sin:Number;

		/**
		 * direction is the direction of the lunge, in degrees.
		 */
		public function LungeAttack( virus:Entity ) {

			super( virus );

			cos = 1;
			sin = 0;

		} //

		public function setDirection( direction:Number=0 ):void {

			cos = Math.cos( direction*Math.PI/180 );
			sin = Math.sin( direction*Math.PI/180 );

		} //

		public function configure( direction:Number=0, distance:Number=200, timeTotal:Number=1, midPercent:Number=0.5 ):void {

			cos = Math.cos( direction*Math.PI/180 );
			sin = Math.sin( direction*Math.PI/180 );

			lungeDistance = distance;

			lungeTime = timeTotal;

			this.midPercent = midPercent;

		} //

		override public function start( doneFunc:Function=null ):void {

			super.start( doneFunc );

			motion.velocity.x = motion.velocity.y = 0;
			motion.previousAcceleration.x = motion.previousAcceleration.y = 0;
			motion.rotationVelocity = 0;

			phase = 1;

			doAccelerate();

		} //

		override public function update( time:Number ):void {

			this.timer += time;

			if ( phase == 1 ) {

				if ( this.timer > phaseTime ) {

					phase++;

					doSlow();			// slow down so the lunge stops with velocity=0

				} //

			} else if ( phase == 2 ) {

				if ( this.timer > phaseTime ) {

					motion.acceleration.x = motion.acceleration.y = 0;
					motion.previousAcceleration.x = motion.previousAcceleration.y = 0;
					motion.velocity.x = motion.velocity.y = 0;
	
					if ( onActionDone != null ) {
						onActionDone();
					}

				} //

			} // end-if.

		} //

		// I worked these equations out on paper. A bunch of algebra with no obvious link
		// between the assumptions and end results.
		private function doAccelerate():void {

			var a:Number = 2*lungeDistance / ( midPercent*lungeTime*lungeTime );

			motion.acceleration.x = a*cos;
			motion.acceleration.y = a*sin;

			// It turns out that the percent of time spent on each part of the trip is equal
			// to the percent of distance covered in each part.
			// This is only true if velocities start and end at 0.
			phaseTime = midPercent*lungeTime;
			timer = 0;

		} //

		private function doSlow():void {

			var a:Number = 2*lungeDistance / ( (midPercent-1)*lungeTime*lungeTime );

			motion.acceleration.x = a*cos;
			motion.acceleration.y = a*sin;

			// It turns out that the percent of time spent on each part of the trip is equal
			// to the percent of distance covered in each part.
			// This is only true if velocities start and end at 0.
			phaseTime = (1 - midPercent)*lungeTime;
			timer = 0;

		} //

	} // End class

} // End package