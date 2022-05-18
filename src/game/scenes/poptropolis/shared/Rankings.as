package game.scenes.poptropolis.shared {

	import game.scenes.poptropolis.shared.data.Competitor;
	import game.scenes.poptropolis.shared.data.MatchType;
	import game.scenes.poptropolis.shared.data.Opponent;
	import game.scenes.poptropolis.shared.data.PoptropolisPlayer;

	public class Rankings {

		public static const NO_RANK:int = -1;

		public function Rankings() {
		} // End function Rankings()

		// assign scores for a particular match.
		// these are stored in a tempScore object, but not permanently saved.
		// alt max is used in games such as hurdles where a maximum score is determined by the game itself.
		public function assignScores( match:MatchType, opponents:Vector.<Opponent> ):void {

			var npc:Opponent;
			//var mod:Number;			// modifier to score of this opponent based on skill.

			for( var i:int = opponents.length-1; i >= 0; i-- ) {

				npc = opponents[i];

				// score was set previously - probably directly by a match scene such as hurdles.
				if ( !isNaN(npc.tempScore) ) {
					npc.tempScore = match.roundScore( npc.tempScore );
					continue;
				} // End-if.

				npc.tempScore = match.getRandScore( npc.skill );

			} // End for-loop.

		} // End function assignScores()

		/**
		 * assigns rankings to the player and opponents in a given match type, based on their assigned
		 * 'tempScores' Identical scores are automatically changed to eliminate ties.
		 * 
		 * I'm not going to pretend to remember how this works. its probably a simple insert or bubblesort.
		 * read it out if you really want to know.
		 */
		public function assignRanks( match:MatchType, player:PoptropolisPlayer, opponents:Vector.<Opponent> ):void {

			var ranks:Vector.<Competitor> = this.makeCompetitorVector( opponents, player );
			var m_id:int = match.id;

			if ( match.invertScore != true ) {
				ranks.sort( this.compareDescending );
			} else {
				ranks.sort( this.compareAscending );
			} // end-if.

			var cur:Competitor, nxt:Competitor;
			var prev:Competitor = ranks[0];

			prev.setRank( m_id, 0 );

			var len:int = ranks.length;
			var j:int;

			// Now set the ranks based on the score sorting.
			// New: Checks for identical scores and alters stats to match.
			// These loops are confusing and very shoddily done.
			for( var i:int = 1; i < len; i++ ) {

				cur = ranks[i];

				if ( match.isBetter( prev.tempScore, cur.tempScore ) ) {
					// These scores are in order, go to next iteration.
					cur.setRank( m_id, i );
					prev = cur;
					continue;
				} // End-if.

				// SCORES OUT OF ORDER.
				if ( cur == player ) {

					// player's score cannot change. prev must get worse -> ( not better since best scores were already sorted. )
					prev.tempScore = match.scoreDown( cur.tempScore );

					ranks[i-1] = cur;					// move player up in rank.
					ranks[i] = prev;					// move npc down in rank.

					cur.setRank( m_id, i - 1 );		// rank up player.

					// swap prev and cur.
					prev = cur;						// player is now previous.
					cur = ranks[i];					// npc is now current.

				} else {

					cur.tempScore = match.scoreDown( prev.tempScore );
					cur.setRank( m_id, i );

				} // End-if.

				if ( cur.tempScore == prev.tempScore ) {
					// scores were changed but didn't change - they must have hit min/max.
					prev = cur;
					continue;
				}

				// now move the 'cur' score down as far as possible in the rank list.
				for( j = i+1; j < len; j++ ) {

					nxt = ranks[j];
					if ( match.isBetter( nxt.tempScore, cur.tempScore ) ) {

						ranks[j-1] = nxt;

					} else {
						break;
					} // End-if.

				} // End for-loop.

				ranks[j-1] = cur;
				/**
				 * Need to repeat this loop in case there are streaks of tie scores which can be further spread out.
				 */
				i--;

			} // End for-loop.

			// trace ranks for testing:
			/*for( i = ranks.length-1; i>=0; i-- ) {
				trace( "RANK: " + ranks[i].getRank( m_id) );
			} //*/

		} // end function assignRanks()

		public function compareDescending( comp1:Competitor, comp2:Competitor ):Number {

			if ( comp1.tempScore > comp2.tempScore ) {
				return -1;
			} else if ( comp1.tempScore == comp2.tempScore ) {
				return 0;
			}

			return 1;

		} //

		public function compareAscending( comp1:Competitor, comp2:Competitor ):Number {

			if ( comp1.tempScore < comp2.tempScore ) {
				return -1;
			} else if ( comp1.tempScore == comp2.tempScore ) {
				return 0;
			}

			return 1;

		} //

		/**
		 * 
		 * returns an vector of player/opponent objects sorted by rank order in a particular event.
		 * ranks[0] = highest scoring player or opponent in that event.
		 * uses INSERTION sort which should be fine for small data sets.
		 * 
		 **/
		public function getRankings( match_id:int, player:PoptropolisPlayer, opponents:Vector.<Opponent> ):Vector.<Competitor> {

			var ranks:Vector.<Competitor> = this.makeCompetitorVector( opponents, player );
			var len:int = ranks.length;

			var cur:Competitor;
			var s:int;
			var insert:int;

			for( var i:int = 1; i < len; i++ ) {

				cur = ranks[i];
				s = cur.getRank( match_id );
				insert = i;

				for( var j:int = i-1; j >= 0; j-- ) {

					if ( ranks[j].getRank( match_id ) < s ) {		// all previous indices are better ranks.
						break;
					}

					ranks[insert] = ranks[j];
					insert = j;

				} // End for-loop.

				ranks[insert] = cur;

			} // End for-loop.

			return ranks;

		} // end function getRanking()

		/**
		 * Returns an array sorted by the average rank (overall score) of each player.
		 * leaders[0] is the competitor currently leading overall.
		 * 
		 **/
		public function getLeaders( player:PoptropolisPlayer, opponents:Vector.<Opponent> ):Vector.<Competitor> {

			var leaders:Vector.<Competitor> = this.makeCompetitorVector( opponents, player );
			var len:int = leaders.length;

			var cur:Object;
			var tot:int;
			var insert:int;

			for( var i:int = 1; i < len; i++ ) {

				cur = leaders[i];
				tot = cur.getTotalRank();
				insert = i;

				for( var j:int = i-1; j >= 0; j-- ) {

					if ( leaders[j].getTotalRank() <= tot ) {		// all previous indices are better (lower) ranks.
						break;
					}

					leaders[insert] = leaders[j];
					insert = j;

				} // End for-loop.

				leaders[insert] = cur;

			} // End for-loop.

			return leaders;

		} // End function getLeaders()

		/**
		 * Get a list of leaders returned as an opponent array. Player is not included.
		 */
		public function getNpcLeaders( opponents:Vector.<Opponent> ):Vector.<Opponent> {

			var leaders:Vector.<Opponent> = opponents.slice();

			var len:int = leaders.length;

			var cur:Object;
			var tot:int;
			var insert:int;

			for( var i:int = 1; i < len; i++ ) {

				cur = leaders[i];
				tot = cur.getTotalRank();
				insert = i;

				for( var j:int = i-1; j >= 0; j-- ) {

					if ( leaders[j].getTotalRank() <= tot ) {		// all previous indices are better (lower) ranks.
						break;
					}

					leaders[insert] = leaders[j];
					insert = j;

				} // End for-loop.

				leaders[insert] = cur;

			} // End for-loop.

			return leaders;

		} // End function getNpcLeaders()

		// assign skills to opponents until tribe-skill data is available.
		// higher skills are better.
		public function assignSkills( opponents:Vector.<Opponent> ):void {

			var len:int = opponents.length;
			var ind:int;

			// uses (len+1) because due to the scoring method, a skill of 100 will always achieve the maximum score.
			// (len+1) gives a buffer against that.
			var increment:Number = 100 / (len+1);

			var skills:Vector.<int> = new Vector.<int>( len );
			for( var i:int = 0; i < len; i++ ) {
				skills[i] = (i+1)*increment;
			} // End for-loop.

			for( i = 0; i < len; i++ ) {

				ind = Math.floor( Math.random()*skills.length );

				opponents[i].skill = skills[ind];

				skills[ind] = skills[skills.length-1];
				skills.length--;

			} // End for-loop.

		} // End function assignSkills()

		/**
		 * Sometimes we need to convert the subclass vectors into a superclass vector.
		 */
		private function makeCompetitorArray( opponents:Vector.<Opponent>, player:PoptropolisPlayer=null ):Array {
			
			var vec:Array = new Array();
			
			var len:int = opponents.length;
			for( var i:int = 0; i < len; i++ ) {

				vec.push( opponents[ i ] );

			} //

			if ( player ) {
				vec.push( player );
			} //

			return vec;

		} //


		/**
		 * Sometimes we need to convert the subclass vectors into a superclass vector.
		 */
		private function makeCompetitorVector( opponents:Vector.<Opponent>, player:PoptropolisPlayer=null ):Vector.<Competitor> {

			var competitors:Vector.<Competitor> = new Vector.<Competitor>();

			var len:int = opponents.length;
			for( var i:int = 0; i < len; i++ ) 
			{
				competitors.push( opponents[ i ] );

			} //

			if ( player ) 
			{
				competitors.push( player );
			} //

			return competitors;

		} //

	} // End class Rankings

} // package