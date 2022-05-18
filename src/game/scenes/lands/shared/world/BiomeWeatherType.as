package game.scenes.lands.shared.world {

	/**
	 * a type of weather and its frequency in a given biome.
	 */

	public class BiomeWeatherType {

		/**
		 * current types:
		 * rain
		 * meteor
		 */
		public var type:String;

		//public var rarity:int = 600;

		/**
		 * rate is 1/rarity and is cached for speed.
		 */
		public var rate:Number;

		/**
		 * rarity is the number of seconds expected to pass before the weather procs.
		 * 3600 is once an hour, 600 is once in ten minutes, 60 once a minute. 0 is not allowed.
		 */
		public function BiomeWeatherType( type:String, rarity:int=300 ) {

			this.type = type;
			this.rate = 1 / rarity;

		}

	} // class

} // package