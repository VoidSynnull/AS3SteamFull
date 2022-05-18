package game.scenes.deepDive3.shared.nodes
{
	import ash.core.Node;
	
	import game.components.entity.collider.RadialCollider;
	import game.components.entity.collider.SceneCollider;
	import game.scenes.deepDive3.shared.components.Orb;
	
	public class OrbNode extends Node
	{
		public var orb:Orb;
		public var sceneCollider:SceneCollider;
		public var radialCollider:RadialCollider;
	}
}