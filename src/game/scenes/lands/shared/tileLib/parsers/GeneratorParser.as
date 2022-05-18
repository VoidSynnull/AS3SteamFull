package game.scenes.lands.shared.tileLib.parsers {
	
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.classes.TileLayer;
	import game.scenes.lands.shared.tileLib.generation.data.TreeData;
	import game.scenes.lands.shared.tileLib.generation.generators.BranchGenerator;
	import game.scenes.lands.shared.tileLib.generation.generators.CaveGenerator;
	import game.scenes.lands.shared.tileLib.generation.generators.CliffGenerator;
	import game.scenes.lands.shared.tileLib.generation.generators.FlatGenerator;
	import game.scenes.lands.shared.tileLib.generation.generators.ForestGenerator;
	import game.scenes.lands.shared.tileLib.generation.generators.MapGenerator;
	import game.scenes.lands.shared.tileLib.generation.generators.OreGenerator;
	import game.scenes.lands.shared.tileLib.generation.generators.TerrainGenerator;
	import game.scenes.lands.shared.tileLib.generation.generators.TunnelGenerator;

	public class GeneratorParser {

		public function GeneratorParser() {
		} //

		/**
		 * xmlList is a list of specific tile renderer classes.
		 */
		public function parseGenerators( xmlList:XMLList, tileMap:TileMap, layer:TileLayer ):Vector.<MapGenerator> {

			var child:XML;
			var len:int = xmlList.length();

			var genList:Vector.<MapGenerator> = new Vector.<MapGenerator>( len, true );
			var generator:MapGenerator;

			var s:String;

			for( var i:int = 0; i < len; i++ ) {
				
				child = xmlList[i];
				
				// for some reason, switch on child.name() directly does not work.
				s = child.name();
				/**
				 * eventually we'll allow individual property assignments for each renderer.
				 */
				switch ( s ) {

					case "terrainGenerator":
						genList[i] = new TerrainGenerator( tileMap );
						break;
					case "forestGenerator":
						genList[i] = this.parseForestGenerator( child, tileMap, layer );
						break;
					case "caveGenerator":
						genList[i] = this.parseCaveGenerator( child, tileMap );		// probably will eventually replace the caveGenerator entirely.
						break;
					case "cliffGenerator":
						genList[i] = this.parseCliffGenerator( child, tileMap );
						break;
					case "oreGenerator":
						genList[i] = this.parseOreGenerator( child, tileMap );
						break;
					case "tunnelGenerator":
						genList[i] = new TunnelGenerator( tileMap );
						break;
					case "branchGenerator":
						genList[i] = new BranchGenerator( tileMap );
						break;
					case "flatGenerator":
						genList[i] = this.parseFlatGenerator( child, tileMap );
						break;

					default:
						trace( "Unknown generator; LandParser: " + s );
						continue;
						
				} // switch
				
				// generators may define a 'pass' which defines when the generator should run relative to others.
				if ( child.hasOwnProperty( "@pass" ) ) {
					genList[i].pass = child.attribute( "pass" );
				} //
				
			} // for-loop.
			
			return genList;
			
		} //

		public function parseOreGenerator( xml:XML, tmap:TileMap ):OreGenerator {
			
			var g:OreGenerator = new OreGenerator( tmap );
			
			if ( xml.hasOwnProperty( "@oreType" ) ) {
				g.oreType = xml.attribute( "oreType" );
			} //
			
			if ( xml.hasOwnProperty( "@oreThreshold" ) ) {
				g.oreThreshold = xml.attribute( "oreThreshold" );
			} //
			
			return g;
			
		} //
		
		public function parseCaveGenerator( xml:XML, tileMap:TileMap ):CaveGenerator {
			
			var g:game.scenes.lands.shared.tileLib.generation.generators.CaveGenerator = new CaveGenerator( tileMap );
			
			if ( xml.hasOwnProperty( "@perlinHeight" ) ) {
				g.perlinHeight = xml.attribute( "perlinHeight" );
			} //
			if ( xml.hasOwnProperty( "@perlinWidth" ) ) {
				g.perlinWidth = xml.attribute( "perlinWidth" );
			} //
			
			if ( xml.hasOwnProperty( "@perlinBase" ) ) {
				g.perlinBase = xml.attribute( "perlinBase" );
			} //
			
			if ( xml.hasOwnProperty( "@cutThreshold" ) ) {
				g.cutThreshold = xml.attribute( "cutThreshold" );
			} //
			
			return g;
			
		} //
		
		public function parseCliffGenerator( xml:XML, tileMap:TileMap ):CliffGenerator {
			
			var g:game.scenes.lands.shared.tileLib.generation.generators.CliffGenerator = new CliffGenerator( tileMap );
			
			if ( xml.hasOwnProperty( "@perlinHeight" ) ) {
				g.perlinHeight = xml.attribute( "perlinHeight" );
			} //
			if ( xml.hasOwnProperty( "@perlinWidth" ) ) {
				g.perlinWidth = xml.attribute( "perlinWidth" );
			} //
			
			if ( xml.hasOwnProperty( "@perlinBase" ) ) {
				g.perlinBase = xml.attribute( "perlinBase" );
			} //
			
			if ( xml.hasOwnProperty( "@cutThreshold" ) ) {
				g.cutThreshold = xml.attribute( "cutThreshold" );
			} //
			
			return g;
			
		} //
		
		public function parseFlatGenerator( xml:XML, tmap:TileMap ):FlatGenerator {
			
			var g:FlatGenerator = new FlatGenerator( tmap );
			
			if ( xml.hasOwnProperty( "@height" ) ) {
				g.height = xml.attribute( "height" );
			} //
			if ( xml.hasOwnProperty( "@tileType" ) ) {
				g.tileType = xml.attribute( "tileType" );
			}

			return g;
			
		} //

		public function parseForestGenerator( xml:XML, tileMap:TileMap, layer:TileLayer ):ForestGenerator {

			var g:ForestGenerator = new ForestGenerator( tileMap, layer );

			if ( xml.hasOwnProperty( "@rootLandMap" ) ) {
				g.rootLandMap = xml.attribute( "rootLandMap" );
			}
			if ( xml.hasOwnProperty( "@rootLandType" ) ) {
				g.rootLandType = xml.attribute( "rootLandType" );
			} //

			g.setTreeTypes( this.parseTreeList( xml.child( "treeType" ) ) );

			return g;

		} //

		public function parseTreeList( list:XMLList ):Vector.<TreeData> {

			var len:int = list.length();
			var treeTypes:Vector.<TreeData> = new Vector.<TreeData>( len, true );

			var child:XML;
			var data:TreeData;

			for( var i:int = 0; i < len; i++ ) {

				child = list[i];

				treeTypes[i] = data = new TreeData();

				if ( child.hasOwnProperty( "@trunkTile" ) ) {
					data.trunkTile = child.attribute( "trunkTile" );
				}
				if ( child.hasOwnProperty( "@leafTile" ) ) {
					data.leafTile = child.attribute( "leafTile" );
				}

				if ( child.hasOwnProperty( "@type" ) ) {

					data.type = child.attribute( "type" );

				} //

			} //

			return treeTypes;

		} //

	} // class

} // package