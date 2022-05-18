package game.data.structs {

	public class GraphEdge {

		/**
		 * Cost of traversing this edge.
		 */
		public var cost:Number;

		public var v1:GraphVertex;
		public var v2:GraphVertex;

		public function GraphEdge( v1:GraphVertex, v2:GraphVertex, cost:Number=1 ) {

			this.v1 = v1;
			this.v2 = v2;

			this.cost = cost;

		} //

	} // End GraphEdge

} // End package