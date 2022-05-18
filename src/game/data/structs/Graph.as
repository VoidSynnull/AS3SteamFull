package game.data.structs {

	public class Graph extends Topology {

		private var vertices:Vector.<GraphVertex>;

		public function Graph( myVertices:Vector.<GraphVertex>=null ) {

			if ( myVertices != null ) {
				this.vertices = myVertices;
			} else {
				this.vertices = new Vector.<GraphVertex>();
			}

		} //

		public function getVertex( i:int ):GraphVertex {
			return this.vertices[ i ];
		}

		public function getClosestVertex( x:Number, y:Number ):GraphVertex {

			var min:Number = Number.MAX_VALUE;
			var best:GraphVertex;

			var d:Number;
			var dx:Number, dy:Number;

			var v:GraphVertex;
			for( var i:int = this.vertices.length-1; i >= 0; i-- ) {

				v = this.vertices[ i ];
				dx = v.x - x;
				dy = v.y - y;

				d = dx*dx + dy*dy;
				if ( d < min ) {
					min = d;
					best = v;
				} //

			} // end for-loop.

			return best;

		} //

		/**
		 * Single direction edge.
		 */
		public function joinDirectedByIndex( start:int, end:int, cost:Number=1 ):void {

			var v1:GraphVertex = this.vertices[ start ];
			v1.addEdge( new GraphEdge( v1, this.vertices[end], cost ) );

		} //

		public function joinDirectedVertices( v1:GraphVertex, v2:GraphVertex, cost:Number=1 ):void {

			v1.addEdge( new GraphEdge( v1, v2, cost ) );

		} //

		public function joinVerticesByIndex( i:int, j:int, cost:Number=1 ):void {

			var v1:GraphVertex = this.vertices[ i ];
			var v2:GraphVertex = this.vertices[ j ];

			/**
			 * TODO: make sure the given vertices aren't already joined.
			 */
			var e:GraphEdge = new GraphEdge( v1, v2, cost );
			v1.addEdge( e );
			v2.addEdge( e );

		} //

		public function joinVertices( v1:GraphVertex, v2:GraphVertex, cost:Number=1 ):void {

			/**
			 * TODO: make sure the given vertices aren't already joined.
			 */
			var e:GraphEdge = new GraphEdge( v1, v2, cost );
			v1.addEdge( e );
			v2.addEdge( e );

		} //

		/**
		 * Return an estimated distance between two graph vertices.
		 * 
		 * When comparing estimates, square roots don't matter, so the results are returned squared.
		 */
		override public function heuristicDistance( v1:TopologyState, v2:TopologyState ):Number {

			var dx:Number = ( v2 as GraphVertex ).x - ( v1 as GraphVertex ).x;
			var dy:Number = ( v2 as GraphVertex ).y - ( v1 as GraphVertex ).y;

			return (dx*dx + dy*dy);

		} //

		/**
		 * TODO: enable link caching, either here or in astar.
		 */
		override public function getLinks( v:TopologyState ):Vector.<TopologyLink> {

			var edges:Vector.<GraphEdge> = ( v as GraphVertex ).edges;

			var links:Vector.<TopologyLink> = new Vector.<TopologyLink>();
			var edge:GraphEdge;

			for( var i:int = edges.length-1; i >= 0; i-- ) {

				edge = edges[ i ];
				links.push( new TopologyLink( (edge.v1 == v ? edge.v2 : edge.v1 ), edge.cost ) );

			} //

			return links;

		} //

	} // End Graph

} // End package