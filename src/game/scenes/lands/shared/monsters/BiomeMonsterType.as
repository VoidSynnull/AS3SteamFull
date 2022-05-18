package game.scenes.lands.shared.monsters {

	import flash.utils.Dictionary;

	public class BiomeMonsterType {

		/**
		 * for each avatar part, say skinColor, hairColor, facial, this dictionary returns
		 * an array of indices from the MonsterBuilder part lists that are acceptable for this biome.
		 * 
		 * if partIndices[ avatarPartName ] returns null, then all monster parts of that type are acceptable for the biome.
		 */
		private var partIndices:Dictionary;

		public function BiomeMonsterType() {

			this.partIndices = new Dictionary();

		} //

		/**
		 * returns a random part index allowed for this biome, or -1 if there are no restrictions.
		 */
		public function getRandomPartIndex( part:String ):int {

			var list:Array = this.partIndices[ part ];
			if ( list == null || list.length == 0 ) {
				return -1;
			}

			// pick a random index from the list of indices.
			return list[ int( Math.random()*list.length ) ];

		} //

		public function setPartArray( part:String, indexArray:Array ):void {

			this.partIndices[ part ] = indexArray;

		} //

		public function getPartArray( part:String ):Array {
			return this.partIndices[ part ];
		}

	} // class

} // package