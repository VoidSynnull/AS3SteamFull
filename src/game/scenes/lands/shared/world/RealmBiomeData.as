package game.scenes.lands.shared.world {

	//import flash.utils.Dictionary;

	/**
	 * information about a realms biome
	 */
	public class RealmBiomeData {

		//public var id:String;

		/**
		 * display name.
		 */
		//public var name:String;

		/**
		 * properties of the biome - currently what weather patterns and meteorological events can happen
		 * in that biome.
		 */
		//public var props:Dictionary;

		public var weatherTypes:Vector.<BiomeWeatherType>;

		/**
		 * the sky colors for the current biome are used to dynamically
		 * draw the sky in the background.
		 */
		public var topSkyColors:Array;
		public var bottomSkyColors:Array;

		public var gravity:Number;

		public function RealmBiomeData() {

			this.weatherTypes = new Vector.<BiomeWeatherType>();

		} //

		/*public function addWeather( type:BiomeWeatherType ):void {
		} //*/

	} // class
	
} // package