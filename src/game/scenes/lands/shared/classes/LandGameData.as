package game.scenes.lands.shared.classes {

	import flash.utils.Dictionary;
	
	import game.scenes.lands.shared.monsters.MonsterBuilder;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.classes.BiomeTileSwapper;
	import game.scenes.lands.shared.tileLib.classes.LandProgress;
	import game.scenes.lands.shared.tileLib.classes.TileLayer;
	import game.scenes.lands.shared.tileLib.classes.WorldRandoms;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;
	import game.scenes.lands.shared.world.LandWorldManager;
	import game.scenes.lands.shared.world.RealmBiomeData;

	public class LandGameData {

		public var worldMgr:LandWorldManager;

		/**
		 * This is the amount all the tileMaps are offset relative to the scene, so they don't stop suddenly at the edge.
		 * All the maps are shifted left, so this number is negative.
		 * 
		 * its needed so frequently that I'm putting it here. Need a better way to handle this value.
		 * maybe move it into the maps themselves.
		 */
		public var mapOffsetX:int;

		/**
		 * inventory of ResourceTypes: experience and poptanium.
		 */
		public var inventory:LandInventory;

		/**
		 * tracks current user level and how close they are to the next level.
		 */
		public var progress:LandProgress;

		/**
		 * All the tile layers in the game.
		 */
		//public var tileLayers:Dictionary;

		/**
		 * All the tileSets from the current biome.
		 */
		public var tileSets:Dictionary;

		public var tileMaps:Dictionary;

		/**
		 * swaps out tile sets when the biome changes.
		 */
		public var tileSwapper:BiomeTileSwapper;

		/**
		 * aids in testing bitmap hit testing by treating the bitmap as a tiled grid
		 * and testing the center of grid tiles for hit colors.
		 */
		public var tileHits:TileBitmapHits;

		/**
		 * this is set to true when data for the current scene exists on the database but did not get sent
		 * back to the client. in this case the scene should not save no matter what the user does,
		 * because their server-scene would get overwritten.
		 */
		public var preventSceneSave:Boolean = false;

		/**
		 * indicates that a scene was altered by the user, or has special features like monsters or loaded templates,
		 * which means the scene must be be saved in data when the user leaves it - rather than regenerated from random seeds.
		 */
		private var _sceneMustSave:Boolean;
		public function get sceneMustSave():Boolean {
			return ( (this.preventSceneSave == false) && this._sceneMustSave );
		}
		public function set sceneMustSave( b:Boolean ):void {

			this._sceneMustSave = this.saveDataPending = b;

		} //

		/**
		 * whether there are still scene changes that need to be saved to server.
		 */
		public var saveDataPending:Boolean;

		/**
		 * true if player has poptanium changes that must be saved to server.
		 */
		public var saveResourcesPending:Boolean;

		/**
		 * maps TileType objects to TileTypeSpecial objects.
		 * for every tileType whose tiles can be interacted with, there will be an entry in this dictionary.
		 */
		public var tileSpecials:Dictionary;

		/**
		 * information about the current biome.
		 * currently used to store weather information.
		 */
		public var biomeData:RealmBiomeData;

		/**
		 * Random numbers used to generate land scenes and for general use.
		 */
		public var worldRandoms:WorldRandoms;

		public var clock:LandClock;

		public var fgLayer:TileLayer;
		public var bgLayer:TileLayer;

		public function LandGameData() {

			this.tileMaps = new Dictionary();
			this.tileSets = new Dictionary();
			this.tileSpecials = new Dictionary( true );
			this.clock = new LandClock();

			this.biomeData = new RealmBiomeData();

		} //

		public function destroy():void {
			this.fgLayer.destroy();
			this.bgLayer.destroy();
			this.progress.destroy();
			this.fgLayer = null;
			this.bgLayer = null;
		}

		public function getFGLayer():TileLayer {
			return this.fgLayer;
		} //

		public function getBGLayer():TileLayer {
			return this.bgLayer;
		} //

		public function getDecalMap():TileMap {

			return this.tileMaps["decal"];

		} //

		public function getTerrainMap():TileMap {
			return this.tileMaps["terrain"];
		}

		public function getDecalSet():TileSet {
			return this.tileSets["decal"];
		}

	} // class

} // package