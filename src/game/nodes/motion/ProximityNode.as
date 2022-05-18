package game.nodes.motion
{
	import ash.core.Node;
	import engine.components.Spatial;
	import game.components.motion.Proximity;

	public class ProximityNode extends Node
	{
		public var currentLoc:Spatial;		// the location of the owning Entity
		public var proximity : Proximity;	// the Proximity to test against

		public function ProximityNode() {}
	}
}