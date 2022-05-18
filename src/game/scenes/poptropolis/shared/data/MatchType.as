package game.scenes.poptropolis.shared.data {

	/**
	 * Represents one type of poptropolis game or event, called a 'Match' to distinguish it from
	 * other programming concepts. The various match types are defined in the 'Matches' class.
	 */
	public class MatchType {

		public var id:int;
		public var displayName:String;		// name displayed to user.

		public var eventName:String;		// name of instructions popup sans 'Instructions'
		//public var scene:Class;			// Scene class of the event.
		//public var sceneName:String;		// name of scene popup

		public var minScore:int;
		public var maxScore:int;
		public var rounding:Number;			// round to nearest number - e.g. 5, 10, 0.1 etc.

		public var unitType:String;			// kg, meters, points, etc.

		public var invertScore:Boolean;		// lower score is better.

		public var precision:int;			// need this since the old rounding code no longer works.

		public function MatchType( n:int, nameStr:String, eventStr:String, max:int, min:int, unit:String="m", round:Number=NaN ) {

			this.maxScore = max;
			this.minScore = min;
			this.id = n;
			this.displayName = nameStr;

			if ( unit == "" ) {
				this.unitType = "m";
			} else {
				this.unitType = unit;
			}

			if ( isNaN( round ) ) {

				this.rounding = 1;
				this.precision = 0;

			} else {

				this.rounding = round;
				// obnoxious. a loop would be better. could also solve log 10.
				if ( round < 0.1 ) {
					this.precision  = 2;
				} else if ( round < 1 ) {
					this.precision = 1;
				} else {
					this.precision = 0;
				}

			}

			this.eventName = eventStr;	// camel case conversion.

		} //

		// Is s1 a better score than s2?
		public function isBetter( s1:Number, s2:Number ):Boolean  {

			if ( this.invertScore == true ) {

				return ( s2 > s1 );

			}
			return ( s1 > s2 );

		}

		public function scoreDown( s:Number ):Number {

			if ( this.invertScore == true ) {
				if ( s + this.rounding > this.maxScore ) {
					return this.maxScore;
				} else {
					return s + this.rounding;
				}
			}

			if ( s - this.rounding < this.minScore ) {
				return this.minScore;
			}

			return s - this.rounding;
		}

		public function roundScore( s:Number ):Number {

			return Math.round( s / this.rounding ) * this.rounding;
		}

		// max can override maxScore; used in hurdles.
		public function getRandScore( skill:int ):Number {

			var score:Number = ( this.maxScore - (this.maxScore-this.minScore)*Math.random()*( 1 - skill/100) );

			return Math.round( score / this.rounding ) * this.rounding;	// round score.
		}

	} // class

} // package