package game.scenes.poptropolis.shared {

	import game.scenes.poptropolis.shared.data.Competitor;
	import game.scenes.poptropolis.shared.data.Opponent;
	import game.scenes.poptropolis.shared.data.PoptropolisPlayer;

	/**
	 * This class will encode (and also decode) all the rank arrays of the individual competitors
	 * so they can be uploaded (downloaded) to the database.
	 * 
	 * While these functions could have been placed in the Rankings class, that deals more with
	 * the actual assignment of scores, score values and score sorting.
	 * 
	 * It should keep things more organized to separate the encoder here.
	 */
	public class RanksEncoder {

		private const NPC_SEPARATOR:String = "#";
		private const ENCODE_RADIX:int = 36;			// Max radix allowed is apparently 36

		public function RanksEncoder() {
		} //

		/**
		 * Encodes the player and opponent's rank data into an encoded String used to store ranks on server.
		 * Each character has all its match ranks encoded, then moves on to the next character.
		 * Ranks have +1 added to remove the negative (undefined) rank.
		 * 
		 * Rank encoding is prevented from being very optimal because we can't guarantee either the number of matches
		 * or the number of opponents. Also not sure if the ascii chars are unicode or not...
		 */
		public function encodeRanks( player:PoptropolisPlayer, opponents:Vector.<Opponent> ):String {

			/**
			 * Assume all rank vectors are the same length. They really should be.
			 */
			var ranks:Vector.<int> = player.getRanks();
			var num_matches:int = ranks.length;
			var result:String = "";
			var rank:int;

			// encode the player's ranks
			for( var i:int = 0; i < num_matches; i++ ) {

				rank = ranks[i] + 1;
				result += rank.toString( this.ENCODE_RADIX );

			} //

			// encode the opponents' ranks
			var num_npcs:int = opponents.length;
			for( var j:int = 0; j < num_npcs; j++ ) {

				result += this.NPC_SEPARATOR;
				ranks = opponents[j].getRanks();

				for( i = 0; i < num_matches; i++ ) {

					rank = ranks[i] + 1;
					result += rank.toString( this.ENCODE_RADIX );

				} //

			} //

			return result;

		} //

		/**
		 * Decodes the String used to store ranks on server and applies rank list to associated Competitor.
		 * String is parsed back into a Vector and reassigned to their respective characters.
		 * @param player
		 * @param opponents
		 * @param dataStr
		 * 
		 */
		public function decodeRanks( player:PoptropolisPlayer, opponents:Vector.<Opponent>, dataStr:String ):void {

			var competitor:Competitor = player;

			var ranks:Vector.<int> = new Vector.<int>();
			//var scoreStrings:Array = dataStr.split( this.NPC_SEPARATOR );

			var charIndex:int = 0;
			var strLen:int = dataStr.length;
			var curChar:String;
			var competitorIndex:int = -1;			// this starts as a virtual index for the player, then moves on to the real incides of the opponents vector.

			var numOpps:int = opponents.length;

			// steps through entire encoded string decoding each char into a vector.
			// When NPC_SEPARATOR char is reached currently decode rank (ranks Vector) is assigned to current competitor.
			// Next competitor is selected and rank continue decoding, repeating process.
			while ( charIndex < strLen ) {

				curChar = dataStr.charAt( charIndex++ );

				if ( curChar == this.NPC_SEPARATOR ) {

					competitor.setRanks( ranks );
					if ( ++competitorIndex >= numOpps ) {
						trace( "unexpected poptropolis npc ranks found." );
						return;
					}
					competitor = opponents[ competitorIndex ] as Competitor;
					ranks = new Vector.<int>();

				} else if ( curChar == "\"" ) {

					continue;

				} else {

					// Note the extra (-1): ranks are raised by 1 during encoding to remove
					// negative (undefined) ranks. Need to restore this after.
					ranks.push( ( parseInt( curChar, this.ENCODE_RADIX ) - 1 ) );
				}

			} // end-while.

			competitor.setRanks( ranks );	// assign last decoded rank to last competitor

		} //

	} // class

} // package