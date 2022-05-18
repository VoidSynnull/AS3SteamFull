package game.data.structs {

	public class Topology {

		public const MAX_UTILITY:Number = Number.MAX_VALUE;
		public const MAX_DISTANCE:Number = Number.MAX_VALUE;

		public function getLinks( node:TopologyState ):Vector.<TopologyLink> {

			return new Vector.<TopologyLink>;

		} //

		/**
		 * A function that returns a guess of the distance between the two locations.
		 * 
		 * This function must always return a monotonic underestimate of the actual distance.
		 * The euclidean distance will almost always satisfy these conditions.
		 */
		public function heuristicDistance( loc1:TopologyState, loc2:TopologyState ):Number {

			return this.MAX_DISTANCE;

		} //

		public function heuristicUtility( loc:TopologyState ):Number {

			return this.MAX_UTILITY;

		} //

	} // end Topology

} // end package