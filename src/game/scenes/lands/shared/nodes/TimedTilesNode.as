package game.scenes.lands.shared.nodes {

	import ash.core.Node;
	
	import game.scenes.lands.shared.components.LandGameComponent;
	import game.scenes.lands.shared.components.TileBlaster;
	import game.scenes.lands.shared.components.TimedTileList;

	public class TimedTilesNode extends Node {

		public var timedList:TimedTileList;
		public var gameComp:LandGameComponent;
		public var blaster:TileBlaster;			// used to explode tiles.

	} // class
	
} // package