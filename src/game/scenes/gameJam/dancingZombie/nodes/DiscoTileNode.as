package game.scenes.gameJam.dancingZombie.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.gameJam.dancingZombie.components.BeatDriven;
	import game.scenes.gameJam.dancingZombie.components.DiscoTile;

	public class DiscoTileNode extends Node
	{
		public var beatDriven:BeatDriven;
		public var display:Display;
		public var spatial:Spatial;
		public var discoTile:DiscoTile;
	}
}