package game.scenes.lands.shared.tileLib.classes {

	/**
	 * indicates the lock state of a TileType:
	 * 
	 * if a tileType is unlocked, it can be edited. if its LOCKED it cannot be edited or seen. (hidden in menu )
	 * if the lockstate is PENDING, then the user can see the tileType in the menu but can't select it yet.
	 */
	public class TileLockState {

		static public const UNLOCKED:int = 0;
		static public const LOCKED:int = 1;
		static public const PENDING:int = 2;

	} //

} // package