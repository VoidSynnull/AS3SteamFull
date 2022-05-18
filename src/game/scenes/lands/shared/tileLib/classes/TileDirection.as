package game.scenes.lands.shared.tileLib.classes {

	/**
	 * Constants representing movement directions.
	 * 
	 * The LandTile borders are meant to be bitwise OR'd and don't work well for representing
	 * general directions.
	 * 
	 * Using these you can turn left/right by adding/subtracting values and mod'ing by 8
	 * Sharp turns are performed by adding/subtracting 2, mod 8
	 * 
	 * Reversing, twisting can be handled in the same way.
	 * 
	 * You can also easily pick a direction with 8*Math.random() without a lot of complicated
	 * if-statements.
	 */
	public class TileDirection {

		static public const TOP:int = 0;
		static public const TOP_RIGHT:int = 1;
		static public const RIGHT:int = 2;
		static public const BOTTOM_RIGHT:int = 3;
		static public const BOTTOM:int = 4;
		static public const BOTTOM_LEFT:int = 5;
		static public const LEFT:int = 6;
		static public const TOP_LEFT:int = 7;

	} // class

} // package