
package game.data.structs {

	public class AStar {

		import game.data.structs.BinaryHeap;

		private var map:Topology;			// Map is the object that contains the dist() function.

		private var queue:BinaryHeap;

		private var dest:TopologyState;

		private var bestPath:Vector.<TopologyState>;

		/**
		 * Maximum number of nodes that will be expanded before the best result so far
		 * is returned.
		 */
		private var maxDepth:int = 14;

		/**
		 * Marks visited path nodes. visit ids are incremented between path searches
		 * so the same nodes are never tried twice within a single path search.
		 */
		private var visit_id:int;

		public function AStar( map:Topology ) {

			this.map = map;

			this.visit_id = 0;

			this.queue = new BinaryHeap();

		} // End function AStar()

		/**
		 * Find a path from the starting location to the ending location.
		 */
		public function findPath( begin:TopologyState, end:TopologyState, path:Vector.<TopologyState>=null ):Vector.<TopologyState> {

			this.dest = end;

			if ( path == null ) {
				this.bestPath = new Vector.<TopologyState>();
			} else {
				path.length = 0;
				this.bestPath = path;
			}

			/**
			 * increment visited marker. check overflow?
			 */
			this.visit_id++;

			var node:PathNode = this.pathLoop( this.makeNode( begin, 0, null ) );

			// build the path backwards, starting with the last node.
			while ( node.loc != begin ) {
				this.bestPath.unshift( node.loc );
				node = node.prev;
			}

			this.queue.empty();

			return this.bestPath;

		} // End function findPath()

		private function pathLoop( n:PathNode ):PathNode {

			while ( n.loc != this.dest ) {

				n.loc.visited = visit_id;	// Mark state as visited for this A* iteration.

				this.expandNode( n );

				n = this.queue.removeMin();
				if ( n == null ) {
					return null;			// no path found.
				}

			} // End while-loop.

			return n;

		} // End function pathLoop()

		public function makeNode( nodeLoc:*, reachDist:Number, prevNode:PathNode ):PathNode {

			var node:PathNode = new PathNode();
			node.loc = nodeLoc;
			node.reachDist = reachDist;		// Distance to reach this location.
			node.prev = prevNode;
			//node.est = e;		// Estimated distance to goal.

			return node;

		} // End function makeNode()

		/**
		 * Possible TO-DO: check for duplicated location nodes, and update with best path option.
		 * ( using Dictionary, probably )
		 */
		private function expandNode( n:PathNode ):void {

			var curLoc:TopologyState = n.loc;

			var d:Number = n.reachDist;
			var links:Vector.<TopologyLink> = this.map.getLinks( curLoc );

			var link:TopologyLink;
			var newNode:PathNode;

			for( var i:Number = links.length-1; i >= 0; i-- ) {

				link = links[i];

				if ( link.loc.visited == this.visit_id ) {	// Link was already visited during
					continue;							// this iteration of A*.
				}

				// makeNode( location, cost to reach node, parent node )
				newNode = this.makeNode( link.loc, (d + link.cost), n );

				// estimated distance to goal = cost to reach node through this route + estimated distance to goal.
				this.queue.insert( newNode.reachDist + this.map.heuristicDistance( newNode.loc, dest ), newNode  );

			} // End for-loop.

		} // End function expandNode()

		/**
		 * findOptimal() looks for an optimal end state - a state that returns
		 * a utility of 0.
		 * 
		 * It's a more abstract operation than finding a path and usually
		 * represents a decision made by an AI.
		 */
		public function findOptimal( begin:TopologyState ):PathNode {

			var node:PathNode = this.makeNode( begin, 0, null );

			this.visit_id++;				// Increment visited marker.
			node = this.optimalLoop( node );

			this.queue.empty();

			return node;

		} // End function findOptimal()

		private function optimalLoop( n:PathNode ):PathNode {

			while ( this.map.heuristicUtility( n.loc ) != 0 ) {

				n.loc.visited = this.visit_id;		// Mark state as visited.
				this.goalExpand( n );

				//queue.getTree();
				n = this.queue.removeMin();
				if ( n == null ) {
					break;
				}

			} // End while-loop.

			return n;

		} // End function optimalLoop()

		private function goalExpand( n:PathNode ):void {

			var curLoc:TopologyState = n.loc;

			var d:Number = n.reachDist;				// distance to reach the previous node.
			var links:Vector.<TopologyLink> = this.map.getLinks( curLoc );

			var link:TopologyLink;
			var node:PathNode;

			for( var i:Number = links.length-1; i >= 0; i-- ) {

				link = links[i];

				if ( link.loc.visited == this.visit_id ) {	// State was previously visited.
					continue;
				}

				// makeNode( location, cost to reach node, parent node )
				node = this.makeNode( link.loc, (d + link.cost), n );

				// The value to minimize in the binary heap is the cost to reach the node,
				// plus the estimated distance to the goal.
				this.queue.insert( node.reachDist + this.map.heuristicUtility( node.loc ), node  );

			} // End for-loop.

		} // End function goalExpand()

		public function setMaxDepth( d:int ):void {

			this.maxDepth = d;

		} //

	} // End class AStar

} // package