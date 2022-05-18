package game.nodes.entity.collider
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.MotionControl;
	import game.components.entity.character.Player;
	import game.components.entity.collider.SceneCollider;
	
	public class PlayerCollisionNode extends Node
	{
		public var spatial : Spatial;
		public var motion : Motion;
		public var collider : SceneCollider;
		public var display : Display;
		public var player : Player;
		public var motionControl : MotionControl;
	}
}