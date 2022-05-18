package game.nodes.specialAbility.character
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.components.motion.TargetSpatial;
	import game.components.specialAbility.character.Follower;
	
	
	public class FollowerNode extends Node
	{
		public var follower:Follower;
		public var spatial:Spatial;
		public var targetSpatial:TargetSpatial;
	}
}