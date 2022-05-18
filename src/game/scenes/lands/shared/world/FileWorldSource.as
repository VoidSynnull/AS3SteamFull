package game.scenes.lands.shared.world {

	/**
	 * this class controls storing and loading worlds from xml files. By default, 'realms' are given
	 * the same names as the biomes, for legacy reasons.
	 */

	import flash.utils.ByteArray;
	
	import engine.util.Command;
	
	import game.scenes.lands.shared.classes.SaveAndLoadFile;
	import game.scenes.lands.shared.tileLib.classes.LandEncoder;

	public class FileWorldSource extends WorldDataSource {

		/**
		 * name of the last save file.
		 */
		private var lastSaveFile:String = "myLand.pop";

		public function FileWorldSource( galaxy:LandGalaxy ) {

			super( galaxy );

		} //

		/**
		 * this function will create a new realm on the server.
		 * the callback callback( realm:LandRealmData, errType:String ) will be triggered with the server response.
		 * 
		 * with err being null if no error.
		 */
		override public function createNewRealm( galaxy:LandGalaxy, biome:String, seed:uint, size:int, name:String, callback:Function ):void {

			var realm:LandRealmData = new LandRealmData( biome, seed, size, name );
			realm.id = galaxy.getUniqueId();

			galaxy.addRealm( realm );

			if ( callback ) {
				callback( realm, null );
			} //

		} //

		override public function loadGalaxy( onLoaded:Function=null ):void {
			
			galaxy.loadSource = "local";
			
			var loader:SaveAndLoadFile = new SaveAndLoadFile();
			loader.browseAndLoad(
				Command.create( this.diskWorldLoaded, galaxy, onLoaded ) );
			
		} //

		/**
		 * load a specific galaxy from the server.
		 * id in this case is the path to to the land.xml world.
		 * 
		 * onLoaded( errType:String )
		 * 	- if no error, errType is null.
		 */
		// Moved to superclass. Used there.
		/*override public function loadServerGalaxy( shell:ShellApi, galaxy:LandGalaxy, id:String, onLoaded:Function=null ):void {

			galaxy.loadSource = "server";

			shell.loadFile( id, Command.create( this.serverWorldLoaded, galaxy, onLoaded ) );
			
		} //*/

		public function saveWorldToDisk( galaxy:LandGalaxy, time:Number=0, onSaved:Function=null ):XML {

			var encoder:LandEncoder = new LandEncoder();
			var xml:XML = encoder.encodeWorld( galaxy, time );

			var saver:SaveAndLoadFile = new SaveAndLoadFile();
			saver.save( xml, this.lastSaveFile, Command.create( this.onFileSaved, onSaved ) );

			return xml;

		} //

		private function onFileSaved( savedName:String, error:String, onSaved:Function ):void {

			this.lastSaveFile = savedName;

			if ( onSaved ) {
				onSaved( error );
			}

		} //

		// moved to superclass
		/*private function serverWorldLoaded( xml:XML, galaxy:LandGalaxy, onLoaded:Function ):void {

			var error:String;

			if ( xml == null ) {
				error = "no data";
			} else {

				var encoder:LandEncoder = new LandEncoder();
				encoder.decodeFileWorld( galaxy, xml );

			}
			if ( onLoaded ) {
				onLoaded( error );
			}

		} //*/

		private function diskWorldLoaded( data:ByteArray, error:String, galaxy:LandGalaxy, onLoaded:Function ):void {

			if ( error == null || error == "" ) {

				var encoder:LandEncoder = new LandEncoder();
				encoder.decodeFileWorld( galaxy, new XML( data.readUTFBytes(data.length) ) );

			}

			if ( onLoaded ) {
				onLoaded( error );
			}

		} //

	} // class

} // package