package game.scenes.lands.shared.classes {

	/**
	 * Some Land tileTypes are interactive - they can be clicked on by the player
	 * and might trigger a variety of actions ( opening doors, explosions, healing )
	 * 
	 * This class gives the interaction information of a single tileType.
	 * 
	 * Eventually this class will probably be subclassed for more specific types of specials.  Or some other mechanism?
	 * so for example, swapTiles will have their own class. Right now
	 * each interaction has a lot of useless data for the stuff it doesnt use.
	 */
	public class TileTypeSpecial {

		/**
		 * a string that xml can tell the program the type of interaction.
		 * this is pretty open-ended since new interactions could always be created.
		 * it would be nice to codify this at some point.
		 * look in tiles.xml to see the special types being defined.
		 * 
		 * some important ones:
		 * food - you can eat this tile
		 * swap - this tile swaps out for another tile. this includes tiles such as doors that switch when open and closed.
		 * 		- most 'treasures' are just swap tiles with a 'bonus' that gets added on interaction.
		 */
		public var specialType:String;

		/**
		 * id of the tileType to swap with this one. must be from the same tileSet or 0.
		 */
		public var swapTile:uint = 0;

		/**
		 * offsets in the case of swapping decals.
		 * this is the offset relative to the top-left of the existing decal where the new decal will be placed.
		 * if the decal is flipped along an axis, the offset is flipped as well.
		 */
		public var offsetX:int = 0;
		public var offsetY:int = 0;

		/**
		 * whether the tile can be clicked by the player.
		 */
		public var clickable:Boolean;

		/**
		 * a bonus amount associated with this tile. for treasure it's poptanium,
		 * for food it's health restored.
		 */
		public var bonus:int = 0;

		/**
		 * when you destroy a refund tile type, you get the cost of the tile type back.
		 * currently used for poptanium treasure bars.
		 */
		public var refund:Boolean=false;

		/**
		 * sound that plays when you interact with the tile type.
		 */
		public var sound:String = "";
		
		//public var timer:Number;
		//public var switchFrame:int;

		public function TileTypeSpecial() {
		} //

	} // class

} // package