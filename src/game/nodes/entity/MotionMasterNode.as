package game.nodes.entity
{
	import ash.core.Node;
	
	import game.components.entity.character.Player;
	import game.components.entity.MotionMaster;
	
	public class MotionMasterNode extends Node
	{
		public var motionMaster:MotionMaster;
		public var player:Player;
	}
}