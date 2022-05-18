package game.nodes.input
{
	import ash.core.Node;
	
	import game.components.entity.character.Player;
	import game.components.motion.MotionControl;
	
	public class MotionControlInputMapNode extends Node
	{
		public var motionControl:MotionControl;
		public var player:Player;
		// TODO :: Want another flag for thsi, not everyone needs to update motion based on input, usually only player. - Bard
		//public var followInput:MotionControlInputMap;
	}
}