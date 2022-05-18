package game.scenes.shrink.livingRoomShrunk.StaticSystem
{
	import ash.core.Node;
	
	import game.components.entity.collider.ClimbCollider;
	import game.components.hit.CurrentHit;
	
	public class StaticClimbNode extends Node
	{
		public var static:Static;
		public var climb:ClimbCollider;
		public var hit:CurrentHit;
	}
}