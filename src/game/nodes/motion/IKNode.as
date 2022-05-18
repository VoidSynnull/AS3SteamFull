package game.nodes.motion
{
	import ash.core.Node;
	
	import game.components.motion.TargetSpatial;
	import game.components.motion.IKControl;
	
	public class IKNode extends Node
	{
		public var control:IKControl;
		public var targetSpatial:TargetSpatial;
	}
}