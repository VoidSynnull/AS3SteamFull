package game.scenes.lands.shared.tileLib.generation.generators {

	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.classes.RandomMap;
	import game.scenes.lands.shared.tileLib.classes.TileLayer;
	import game.scenes.lands.shared.tileLib.generation.builders.BigPineBuilder;
	import game.scenes.lands.shared.tileLib.generation.builders.BigTreeBuilder;
	import game.scenes.lands.shared.tileLib.generation.builders.BushBuilder;
	import game.scenes.lands.shared.tileLib.generation.builders.CactusBuilder;
	import game.scenes.lands.shared.tileLib.generation.data.TreeData;

	public class ForestGenerator extends MapGenerator {

		public var rootLandMap:String = "terrain";

		/**
		 * terrain type that the tree can be rooted in. currently 'grass'
		 * maybe change this to refer to the NAME of a terrain? seems safer.
		 */
		public var rootLandType:uint = 4;

		/**
		 * builds pine trees.
		 */
		private var pineBuilder:BigPineBuilder;
		private var bigBuilder:BigTreeBuilder;
		private var bushBuilder:BushBuilder;
		private var cactusBuilder:CactusBuilder;

		private var treeTypes:Vector.<TreeData>;

		private var tileLayer:TileLayer;

		public function ForestGenerator( tmap:TileMap, layer:TileLayer ) {

			super( tmap );

			this.tileLayer = layer;

		} //

		override public function generate( gameData:LandGameData=null ):void {

			this.randomMap = gameData.worldRandoms.randMap;
			var treeMap:RandomMap = gameData.worldRandoms.treeMap;

			/**
			 * ugh i know. maybe fix later.
			 */
			var rowOffset:int = this.tileLayer.randOffset;
			var terrainMap:TileMap = gameData.tileMaps[ this.rootLandMap ];

			var tile:LandTile;

			// conversion of coordinates between terrain tiles and tree tiles.
			var coordScale:Number = terrainMap.tileSize / this.tileMap.tileSize;

			// skip a few top rows since there's no room for a tree at that height.
			for( var c:int = terrainMap.cols-1; c >= 0; c-- ) {
				
				tile = this.getTopTile( terrainMap, c );
				if ( tile == null || tile.type != this.rootLandType ) {
					continue;
				}

				// here's the tricky bit. first need to decide on the left or right tile.
				// need to check there are no other nearby tiles.
				if ( treeMap.getNumberAt( c, tile.row+rowOffset ) > 0.6 ) {

					if ( this.randomMap.getRandom() < 0.5 ) {
						this.buildTreeAt( tile.row*coordScale, c*coordScale, gameData );
					} else {
						this.buildTreeAt( tile.row*coordScale, c*coordScale+1, gameData );
					}
					// save some time. not going to build another tree in this area.
					c -= 3;

				} //

			} // for-loop.

			this.pineBuilder = null;
			this.bigBuilder = null;
			this.bushBuilder = null;
			this.cactusBuilder = null;

		} // generate()

		private function buildTreeAt( r:int, c:int, gameData:LandGameData ):void {

			if ( c < 0 || c >= this.tileMap.cols ) {
				return;
			}
			if ( r >= this.tileMap.rows-1 ) {
				r = this.tileMap.rows-1;
			} else {	
				r++;							// increment the row to 'root' the tree further into the ground.
			}

			if ( this.isNonEmptyInRect( r-2, r, c-6, c+6, this.tileMap ) ) {
				return;
			}

			var i:int = this.randomMap.getNumberAt( c, r )*this.treeTypes.length;

			var type:TreeData = this.treeTypes[ i ];
			if ( type.type == "pine" ) {

				if ( !this.pineBuilder ) {

					this.pineBuilder = new BigPineBuilder( this.tileMap );
					this.pineBuilder.setRandomMap( this.randomMap );

				} //
				this.pineBuilder.build( r, c, type );

			} else if ( type.type == "bush" ) {

				if ( !this.bushBuilder ) {
					this.bushBuilder = new BushBuilder( this.tileMap );
				}
				this.bushBuilder.generateAt( r, c, type, gameData );

			} else if ( type.type == "cactus" ) {

				if ( !this.cactusBuilder ) {
					this.cactusBuilder = new CactusBuilder( this.tileMap );
					this.cactusBuilder.setRandomMap( this.randomMap );
				}
				this.cactusBuilder.build( r, c, type );

			} else {

				if ( !this.bigBuilder ) {
					this.bigBuilder = new BigTreeBuilder( this.tileMap );
					this.bigBuilder.setRandomMap( this.randomMap );
				}
				this.bigBuilder.build( r, c, type )

			} //

		} //

		public function setTreeTypes( types:Vector.<TreeData> ):void {

			this.treeTypes = types;

		} //

	} //class

} // package