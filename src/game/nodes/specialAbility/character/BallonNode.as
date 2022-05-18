package game.nodes.specialAbility.character
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.components.motion.FollowTarget;
	import game.components.specialAbility.character.Balloon;
	
	
	public class BallonNode extends Node
	{
		public var balloon:Balloon;
		public var spatial:Spatial;
		public var followTarget:FollowTarget;
	}
}