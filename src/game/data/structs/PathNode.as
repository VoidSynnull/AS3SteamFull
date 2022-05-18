package game.data.structs {

	public class PathNode {

		public var loc:TopologyState;

		/**
		 * Distance to reach this node from the previous node.
		 */
		public var reachDist:Number;

		/**
		 * Current estimate of the distance of this node from the goal node.
		 * Don't seem to need to save this for any reason.
		 */
		//public var goalDist:Number;

		/**
		 * Node that led to the expansion of this node. This is the previous
		 * node on the best path leading to this node.
		 */
		public var prev:PathNode;

		public function PathNode() {
		} //

	} // End PathNode

} // End package