package game.scenes.lands.shared.tileLib.templates {

	import flash.utils.Dictionary;
	
	import game.scenes.lands.shared.tileLib.classes.LandAssetLoader;
	import game.scenes.lands.shared.tileLib.tileTypes.ClipTileType;

	public class TemplateRegister {

		private var list:Vector.<TemplateFileInfo>;

		/**
		 * move this somewhere else later? regular templates can contain treasures but these
		 * will proc as part of special treasure generation.
		 */
		private var treasures:Vector.<TemplateFileInfo>;

		/**
		 * Random props to place underground.
		 * Currently the xml for treasure props is just:
		 * <treasureProps ids="comma-id-list" />
		 * but this can be expanded to include sub-tags with drop rates.
		 */
		private var treasureProps:Vector.<ClipTileType>;

		public function TemplateRegister() {
		} //

		public function parseRegistry( xml:XML, propTiles:Dictionary, assetLoader:LandAssetLoader ):void {

			var templateNodes:XMLList = xml.template;

			var len:int = templateNodes.length();

			this.list = new Vector.<TemplateFileInfo>( len, true );

			var infoNode:XML;
			for( var i:int = 0; i < len; i++ ) {

				infoNode = templateNodes[i];
				// infoNode.@rate
				this.list[i] = new TemplateFileInfo( infoNode.@url );

			} //

			// TREASURE TEMPLATES
			templateNodes = xml.treasure;
			len = templateNodes.length();
			this.treasures = new Vector.<TemplateFileInfo>( len, true );

			for( i = 0; i < len; i++ ) {

				infoNode = templateNodes[i];
				// infoNode.@rate
				this.treasures[i] = new TemplateFileInfo( infoNode.@url );

			} //

			// TREASURE PROPS. this can be expanded in the future with more options.
			this.treasureProps = new Vector.<ClipTileType>();
			templateNodes = xml.treasureProps;
			if ( !templateNodes ) {
				return;
			} //
			infoNode = templateNodes[0];
			if ( infoNode ) {
				this.parsePropTreasures( infoNode, propTiles, assetLoader );
			}


		} // parseRegistry()

		private function parsePropTreasures( treasureNode:XML, props:Dictionary, assetLoader:LandAssetLoader ):void {

			var string_ids:Array = ( treasureNode.attribute( "ids" ).toString() ).split(",");
			var prop:ClipTileType;

			for( var i:int = string_ids.length-1; i >= 0; i-- ) {

				prop = props[ parseInt( string_ids[i] ) ];
				if ( !prop ) {
					continue;
				}
				this.treasureProps.push( prop );

			} //

			// this IS necessary since it's impossible to place a treasure prop without knowing the clip dimensions,
			// and that information is only available from the prop swf.
			assetLoader.loadDecalVector( this.treasureProps );

		} //

		public function getRandomProp():ClipTileType {
			return this.treasureProps[ Math.floor( Math.random()*this.treasureProps.length ) ];
		}

		public function getRandomTreasure():TemplateFileInfo {

			return this.treasures[ Math.floor( Math.random()*this.treasures.length ) ];

		} //

		public function getRandom():TemplateFileInfo {

			return this.list[ Math.floor( Math.random()*this.list.length ) ];

		} //

	} // class

} // package