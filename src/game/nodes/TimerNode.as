package game.nodes
{
	import ash.core.Node;
	import game.components.Timer;

	public class TimerNode extends Node
	{
		public var timer : Timer;     // Only the player responds to control input.
	}
}
