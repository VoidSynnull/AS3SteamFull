package game.scenes.poptropolis.shared.data {

	import ash.core.Entity;
	
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.profile.TribeData;
	import game.util.SkinUtils;
	import game.util.TribeUtils;

	public class Opponent extends Competitor {

		/**
		 * The way opponent look_ids are stored requires some explanation. originally all the looks were kept
		 * in a single array, and the look_id was the index of the look within the look array. (too much data to save the entire look data)
		 * 
		 * However, it was decided there should be an (approximately) equal number of boy and girl competitors. To make this clear
		 * I kept the two look arrays separate: boy look arrays and girl look arrays - it simplifies a lot of things.
		 * 
		 * But we still only want to have ONE look_id stored in the database. So, both boy and girl look_ids are stored as the index
		 * in their respective look-arrays, but boy look_ids have the BOY_OFFSET of 1000 added to them, marking them off as boys.
		 * 
		 * This uniquely identifies which look array to use and which look index within the array to use.
		 */
		static private var BOY_OFFSET:int = 1000;

		static public var GirlLooks:Vector.<LookData>;
		static public var BoyLooks:Vector.<LookData>;

		public var skill:int;
		public var lookId:int;

		public function Opponent() {
		}

		/**
		 * Encode variables into a server/lso friendly Object
		 * @return 
		 */
		public function encode():Object {

			return { look:this.lookId, skill:this.skill, tribeID:TribeUtils.convertId(super.tribe.index, false ) };

		} //
		
		/**
		 * Decodes object from server/lso, converting back Opponent variables
		 * @param oppData
		 */
		public function decode( oppData:Object ):void {

			this.lookId = oppData.look;
			this.skill = oppData.skill;

			// oppData[1] is the tribe id from server ( starts at 4001 )
			super.tribe = TribeUtils.getTribeDataByIndex( oppData.tribeID as int );

		} //

		// ************************* LOOK AND RANDOMIZERS ************************* //
		
		public function getLook():LookData {

			var look:LookData; 
			if ( this.lookId >= BOY_OFFSET ) {
				look = BoyLooks[ this.lookId - BOY_OFFSET ];
			} else {
				look = GirlLooks[ this.lookId ];
			}
			look.applyAspect( new LookAspectData( SkinUtils.SHIRT, super.tribe.jersey ) );
			look.applyAspect( new LookAspectData( SkinUtils.PANTS, super.tribe.jersey ) );

			return look;

		}

		public function applyLook( charEntity:Entity ):void {

			SkinUtils.applyLook( charEntity, getLook(), true );

		} 

		// returns an array of unique look ids that can be used for opponents.
		// why so complicated? Must pick equal number of boys and girls and never re-use a look.
		// the method is to make a list of ids and then select/remove elements from that list.
		static public function SelectLooks( num_looks:int ):Vector.<int> {

			// list of look ids to return.
			var looks:Vector.<int> = new Vector.<int>();

			// PICK GIRLS.
			var count:Number = Math.floor( num_looks/2 );			// number of girls to pick. later used for boys.
			if ( num_looks % 2 != 0 && Math.random() < 0.5 ) {
				count++;	// odd number of players. determine if extra should be boy or girl.
			}

			var ind:int;			// index of girl id to pick. this index is NOT an id, it is an index to an id.
			var i:int;
			var numLooks:int = GirlLooks.length;

			var ids:Vector.<int> = new Vector.<int>( numLooks );			// id numbers for girl looks.
			for( i = 0; i < numLooks; i++ ) {
				ids[i] = i;
			}

			for( i = 0; i < count; i++ ) {
				ind = Math.floor( Math.random()*numLooks );				// index of picked id.
				looks.push( ids[ind] );								// save picked id.

				numLooks--;
				ids[ind] = ids[numLooks];								// fast removal of id as an option.
				ids.length = numLooks;
			} //

			// PICK BOYS.
			ids.length = numLooks = BoyLooks.length				// ids for boys now.
			for( i = 0; i < numLooks; i++ ) {
				ids[i] = BOY_OFFSET + i;
			}

			count = num_looks - count;					// number of boys to pick.
			for( i = 0; i < count; i++ ) {

				ind = Math.floor( Math.random()*numLooks );				// index of picked id.
				looks.push( ids[ind] );								// save picked id.

				numLooks--;
				ids[ind] = ids[numLooks];								// fast removal of id as an option.
				ids.length = numLooks;

			} //

			return looks;

		} //

		static public function InitLooks( xmlData:XMLList ):void {

			Opponent.GirlLooks = new Vector.<LookData>();
			Opponent.BoyLooks = new Vector.<LookData>();

			var look:LookData;
			for( var i:int = 0; i < xmlData.length(); i++ ) {

				look = new LookData( xmlData[i] );
				if ( look.getValue( SkinUtils.GENDER ) == SkinUtils.GENDER_FEMALE ) {
					Opponent.GirlLooks.push( look );
				} else {
					Opponent.BoyLooks.push( look );
				}

			} // end for-loop.

		} //

	} // class

} // package