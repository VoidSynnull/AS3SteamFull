package game.scenes.lands.shared.tileLib.parsers {

	import game.scenes.lands.shared.monsters.BiomeMonsterType;
	import game.scenes.lands.shared.monsters.MonsterBuilder;
	
	public class MonsterParser {
		
		public function MonsterParser() {
		} //

		public function parse( xmlRoot:XML, builder:MonsterBuilder ):void {

			var parts:XML = xmlRoot.parts[0];

			builder.setPropertyList( "variants", this.parseStringOptions( parts.variant ) );

			builder.setPropertyList( "facial", this.parseStringOptions( parts.facial ) );
			builder.setPropertyList( "eyes", this.parseStringOptions( parts.eyes ) );
			builder.setPropertyList( "marks", this.parseStringOptions( parts.marks ) );
			builder.setPropertyList( "mouth", this.parseStringOptions( parts.mouth ) );
			builder.setPropertyList( "hair", this.parseStringOptions( parts.hair ) );

			builder.setPropertyList( "shirt", this.parseStringOptions( parts.shirt ) );
			builder.setPropertyList( "pants", this.parseStringOptions( parts.pants ) );
			builder.setPropertyList( "overshirt", this.parseStringOptions( parts.overshirt ) );
			builder.setPropertyList( "overpants", this.parseStringOptions( parts.overpants ) );

			builder.setPropertyList( "pack", this.parseStringOptions( parts.pack ) );
			builder.setPropertyList( "item", this.parseStringOptions( parts.item ) );

			builder.setPropertyList( "skinColor", this.parseIntOptions( parts.skinColor ) );
			builder.setPropertyList( "hairColor", this.parseIntOptions( parts.hairColor ) );

			var biomes:XMLList = xmlRoot.biome;
			for( var i:int = biomes.length()-1; i >= 0; i-- ) {

				this.parseBiomeType( biomes[i], builder );

			} //

		} // parse()

		/**
		 * parse collections of monster part index restrictions for a given biome.
		 */
		private function parseBiomeType( xml:XML, builder:MonsterBuilder ):void {

			var type:BiomeMonsterType = new BiomeMonsterType();

			var parts:XMLList = xml.children();
			var partNode:XML;
			for( var i:int = parts.length()-1; i >= 0; i-- ) {

				partNode = parts[i];
				type.setPartArray( partNode.name(), this.parseIndexList( partNode ) );

			} // end for-loop.

			builder.addBiomeType( xml.@name, type );

		} //

		private function parseStringOptions( lookList:XMLList ):Array {

			if ( lookList.length() == 0 ) {
				return new Array();
			}

			var opts:String = lookList[0];
			return opts.split( "," );

		} //

		private function parseIntOptions( lookList:XMLList ):Array {

			if ( lookList.length() == 0 ) {
				return new Array();
			}

			var opts:String = lookList[0];
			var a:Array = opts.split( "," );

			for( var i:int = a.length-1; i >= 0; i-- ) {

				a[i] = parseInt( a[i] );

			} //

			return a;

		} //

		private function parseIndexList( indexList:XML ):Array {
			
			var opts:String = indexList;
			var a:Array = opts.split( "," );

			for( var i:int = a.length-1; i >= 0; i-- ) {
				
				a[i] = parseInt( a[i] );
				
			} //
			
			return a;
			
		} //

	} // class

} // package