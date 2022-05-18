package game.scenes.virusHunter.joesCondo.nodes {

	import ash.core.Node;
	
	import engine.components.Motion;
	
	import game.components.hit.CurrentHit;
	import game.components.entity.collider.PlatformCollider;
	import game.components.hit.Zone;
	import game.scenes.virusHunter.joesCondo.components.RollingObject;

	public class RollingObjectNode extends Node {

		public var roller:RollingObject;
		public var motion:Motion;
		public var zoneHit:Zone;
		public var curHit:CurrentHit;
		public var collider:PlatformCollider;

	} //

} // End package