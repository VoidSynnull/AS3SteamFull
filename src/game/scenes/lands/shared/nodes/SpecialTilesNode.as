package game.scenes.lands.shared.nodes {

	// A special node is a game-wide node (only one node per system) that tracks information about special tiles onscreen.
	// currently it only contains timedTiles, but other information like tnt tiles, trap tiles, might be added?

	import ash.core.Node;
	
	import game.scenes.lands.shared.components.LandGameComponent;
	import game.scenes.lands.shared.components.TimedTileList;
		
	public class SpecialTilesNode extends Node {

		public var timers:TimedTileList;
		// game data will have the special tiles defined.
		public var gameData:LandGameComponent;

	} // class
	
} // package