package game.scenes.gameJam.dancingZombie.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.scenes.gameJam.dancingZombie.components.BeatDriven;
	import game.scenes.gameJam.dancingZombie.components.Zombie;
	
	public class ZombieNode extends Node
	{
		public var zombie:Zombie;
		public var beat:BeatDriven;
		public var spatial:Spatial;
		public var display:Display;
	}
}