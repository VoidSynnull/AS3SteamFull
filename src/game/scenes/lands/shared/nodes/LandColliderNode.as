package game.scenes.lands.shared.nodes {
	
	import ash.core.Node;
	
	import game.components.entity.collider.BitmapCollider;
	import game.components.motion.Edge;
	import game.scenes.lands.shared.components.HitTileComponent;


	public class LandColliderNode extends Node {

		public var bitmapCollider:BitmapCollider;

		public var hitTile:HitTileComponent;
		public var edge:Edge;

	} // class

} // package