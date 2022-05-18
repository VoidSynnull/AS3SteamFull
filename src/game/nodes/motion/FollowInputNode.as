package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.components.input.Input;
	import game.components.motion.FollowInput;

	public class FollowInputNode extends Node
	{
		public var spatial:Spatial;
		public var input:Input;
		public var followInput:FollowInput;
	}
}