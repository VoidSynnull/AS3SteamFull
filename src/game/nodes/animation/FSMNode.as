package game.nodes.animation
{
	import ash.core.Node;
	
	import game.components.animation.FSMControl;
	import game.components.animation.FSMMaster;

	public class FSMNode extends Node
	{
		public var fsmControl:FSMControl;
		public var masterFlag:FSMMaster;
		
	}
}
