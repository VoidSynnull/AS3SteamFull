package game.scenes.gameJam.zombieDefense.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.gameJam.zombieDefense.components.DefenseZombie;
	
	public class DefenseZombieNode extends Node
	{
		public var id:Id;
		public var zombie:DefenseZombie;
		public var spatial:Spatial;
		public var motion:Motion;
		public var display:Display;
	}
}