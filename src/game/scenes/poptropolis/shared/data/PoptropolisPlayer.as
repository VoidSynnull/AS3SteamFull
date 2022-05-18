package game.scenes.poptropolis.shared.data {

	import game.data.profile.TribeData;

	public class PoptropolisPlayer extends Competitor {

		public function PoptropolisPlayer( myTribe:TribeData ) {

			super.tribe = myTribe;

		} //

		public function setMatchScore( matchType:int, s:Number ):void {

			// tempScore used for rank assignments.
			//this.scores[ matchType ] =
			this.tempScore = s;

		}

		public function getMatchScore( matchType:int=-1 ):int {

			return super.tempScore;
			
		} //

		// clears scores AND rankings, since one is effectively the same as the other.
		/*
		public function clearScores():void
		{
			this.scores = new Vector.<int>( Matches.NUM_TYPES );

			for( var i:int = this.scores.length-1; i >= 0; i-- )
			{
				this.scores[i] = 0;
			}

			this.clearRanks();
		}
		*/
		override public function isNpc():Boolean {
			return false;
		}

	} //

} //