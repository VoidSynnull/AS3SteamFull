package game.scenes.poptropolis.shared.data {

	import game.data.profile.TribeData;
	import game.scenes.poptropolis.shared.Rankings;

	// superclass of Player and Opponent classes.
	// Implements functions and variables common to both the player and opponents.
	public class Competitor {

		public var tribe:TribeData;
		/**
		 * Ranks this competitor got in each match type.
		 * The match type is the index. Perhaps a better name would have been matchRanks?
		 */
		private var _ranks:Vector.<int>;
		public var totalRank:int;			// sum of all (nonnegative) ranks in each event.
		public var tempScore:Number;	// used to set scores for a game in progress, simplifies sorting algorithms for scores.

		public function Competitor() {

			this.totalRank = Rankings.NO_RANK; 

		} //

		// ************************* RANKS ************************* //

		/**
		 * Sets the score for the next reported match.
		 * The score will only be saved if the scores are subsequently reported
		 * with poptropolis.reportScore()
		 */
		public function setScore( n:Number ):void {
			this.tempScore = n;
		}

		// returns tempScore.
		public function getScore():Number {
			return this.tempScore;
		}
		
		/**
		 * Sets the score for the next reported match.
		 * The score will only be saved if the scores are subsequently reported
		 * with poptropolis.reportScore()
		 */
		public function setTribe( tribeData:TribeData ):void {
			this.tribe = tribeData;
		}

		// Player class overrides
		public function isNpc():Boolean {
			return true;
		}

		public function setRanks( arr:Vector.<int> ):void {

			if ( arr == null ) {
				this.clearRanks();
				return;
			}

			for( var i:int = arr.length-1; i >= 0; i-- ) {
				if ( isNaN( arr[i] ) ) {
					arr[i] = Rankings.NO_RANK;
				}
			}
			this._ranks = arr;

		} //

		public function getRanks():Vector.<int> {
			return this._ranks;
		}

		public function clearRanks():void {

			var len:int = Matches.NUM_TYPES;

			this._ranks = new Vector.<int>( len );

			for( var i:int = 0; i < len; i++ ) {

				this._ranks[i] = Rankings.NO_RANK;

			} //

		} //

		public function setRank( matchType:int, rank:int ):void {

			if( this._ranks != null )
			{
				this._ranks[ matchType ] = rank;
			}
			else
			{
				trace(this," :: Error :: setRank : cannot set rank because ranks has yet to be defined.");
			}
		}

		public function getRank( matchType:int ):int {
			return this._ranks[ matchType ];
		}

		public function getTotalRank():int {

			if ( this.totalRank != Rankings.NO_RANK ) {
				return this.totalRank;
			}

			var cnt:int = 0;
			for( var i:int = this._ranks.length-1; i >= 0; i-- ) {

				if ( _ranks[i] != -1 ) {
					cnt += this._ranks[i];
				}

			} //

			this.totalRank = cnt;
			return this.totalRank;

		} //

	} //class

} // package