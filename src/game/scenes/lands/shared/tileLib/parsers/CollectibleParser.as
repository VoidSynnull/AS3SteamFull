package game.scenes.lands.shared.tileLib.parsers {

	import flash.utils.Dictionary;
	
	import game.scenes.lands.shared.classes.CollectibleResource;
	import game.scenes.lands.shared.classes.ResourceType;
	import game.util.DataUtils;

	/**
	 * parser for tile collectibles.
	 */
	public class CollectibleParser {

		public function CollectibleParser() {

		} //

		public function parse( xml:XML ):Dictionary {

			var types:Dictionary = new Dictionary();

			var xmlList:XMLList = xml.child( "resource" );
			var len:int = xmlList.length();

			var child:XML;

			var resource:ResourceType;

			for( var i:int = 0; i < len; i++ ) {

				child = xmlList[i];

				if ( child.hasOwnProperty( "@swf" ) ) {

					var collectible:CollectibleResource = new CollectibleResource();
					resource = collectible;

					collectible.swf = child.attribute( "swf" );
					if ( child.hasOwnProperty( "@bitmap" ) ) {
						collectible.useBitmap = DataUtils.getBoolean( child.attribute( "bitmap" ) );
					}

				} else {
					resource = new ResourceType();
				}

				if ( child.hasOwnProperty( "@name" ) ) {
					resource.name = child.attribute( "name" );
				}
				if ( child.hasOwnProperty( "@type" ) ) {

					resource.type = child.attribute( "type" );
					types[ resource.type ] = resource;

				} //

			} //

			return types;

		} //

	} // class

} // package