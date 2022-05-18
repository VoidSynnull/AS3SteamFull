package game.scenes.hub.shared.nodes
{
	import ash.core.Node;
	
	import game.components.animation.FSMControl;
	import game.scenes.hub.shared.components.SnowballPlayer;
	
	public class SnowballPlayerNode extends Node
	{
		public var snowballPlayer:SnowballPlayer;
		public var fsmControl:FSMControl;
	}
}