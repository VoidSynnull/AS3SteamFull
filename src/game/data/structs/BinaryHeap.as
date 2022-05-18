package game.data.structs {

	/**
	 * 
	 * BinaryHeap implementation of PriorityQueue.
	 * Useful mainly for pathfinding and making priority decisions.
	 * 
	 * It can also be used to sort data in a time complexity on par with QuickSort, MergeStort
	 * 
	 * Consider making StructNode pool for efficient reuse of structNodes.
	 */
	public class BinaryHeap {

		public static const ROOT:int = 0;

		/**
		 * Current end index of the heap vector.
		 */
		private var END:int;

		/**
		 * Vector storing the heap node.
		 */
		private var heap:Vector.<StructNode>;			// array storing heap nodes.

		public function BinaryHeap() {

			this.heap = new Vector.<StructNode>();
			this.END = 0;

		} // End function BinaryHeap

		public function insert( k:Number, o:* ):void {

			// insert at end up heap and push up.
			this.pushUp( this.END, new StructNode( k, o ) );
			this.END++;

		} // End function insert()

		public function peekMin():* {

			return this.heap[ BinaryHeap.ROOT ].obj;

		} // end function peekMin()

		public function removeMin():* {

			var min:StructNode = this.heap[ BinaryHeap.ROOT];

			this.pushDown( ROOT, this.heap[--this.END] );
			this.heap.length = this.END;

			return min.obj;

		} // End function removeMin()

		public function findObject( k:Number ):* {

			for( var i:int = BinaryHeap.ROOT; i < this.END; i++ ) {

				if ( this.heap[i].key == k ) {
					return heap[i].obj;
				}

			} // End for-loop.

			return null;

		} // End function findObject()

		public function updateKey( o:*, new_key:Number ):void {

			for( var i:int = BinaryHeap.ROOT; i < this.END; i++ ) {

				if ( this.heap[i].obj == o ) {

					if ( new_key < this.heap[i].key ) {

						this.heap[ i ].key = new_key;
						this.pushUp( i, this.heap[ i ] );

					} else {

						this.heap[i].key = new_key;
						this.pushDown( i, this.heap[ i ] );

					} // End-if.

				} //

			} // End for-loop.

		} // End function findObject()

		/**
		 * Push a node at a given index up the heap as far as it can go.
		 * As long as parent nodes have lower indices, it goes up.
		 */
		private function pushUp( ind:int, node:StructNode ):void {

			var k:Number = node.key;

			var pIndex:Number = Math.floor( (ind-1)/2 );
			var pNode:StructNode;

			while ( pIndex >= 0 ) {

				pNode = this.heap[ pIndex ];
				if ( pNode.key <= k ) {
					break;
				} //

				this.heap[ ind ] = pNode;		// move parent node down, advance to next parent.
				ind = pIndex;
				pIndex = Math.floor( (ind-1) / 2 );

			} // end-while.

			this.heap[ind] = node;

		} // End function pushUp()

		/**
		 * Push a node down the heap as far as it will go.
		 */
		private function pushDown( ind:int, node:StructNode ):void {

			var k:Number = node.key;
			var c1:int, c2:int;
			var min:int;

			do {

				c1 = 2*ind + 1;			// index of first child.
				if ( c1 >= this.END ) {
					break;
				}
				c2 = c1 + 1;			// index of second child.
				if ( c2 >= this.END ) {
					min = c1;
				} else {
					// index of child with minimal key.
					min = ( this.heap[c1].key <= this.heap[c2].key ) ? c1 : c2;
				}

				if ( this.heap[min].key >= k ) {
					// Smallest child index is greater than node index.
					break;
				} //

				// swap child1 and node.
				this.heap[ind] = this.heap[min];
				ind = min;

			} while( ind < this.END ); // End-while.

			this.heap[ind] = node;

		} // End function pushDown()

		public function empty():void {

			this.END = BinaryHeap.ROOT;
			this.heap.length = 0;

		} //

		public function getParentIndex( index:int ):int {

			return Math.floor( (index-1) / 2 );

		} // getParentIndex()

		// returns index of first child.
		public function getChildIndex( index:int ):int {

			return (2*index + 1);

		} // end function getChildIndex()

		// restore heap order in the heap array, after updating keys, for instance.
		public function heapify( key_prop:String ):void {

			if ( this.END <= 1 ) {
				return;
			}

			var ind:int = this.END-1;
			while ( ind >= 0 ) {
				this.heap[ind].key = this.heap[ind].obj[key_prop];
				ind--;
			} //

			ind = Math.floor( this.END/2 );

			while( ind >= 0 ) {

				this.pushDown( ind, this.heap[ ind ] );
				ind--;

			} // End-while.

		} // End function heapify()

		/**
		 * Update all key-values in the heap with the indicated property
		 * of the objects stored in the heap.
		 * 
		 * If the key-value has changed from before, heap order will be restored.
		 */
		public function updateAllKeys( key_prop:String ):void {

			var n:StructNode;
			var k:Number;

			for( var i:int = 0; i < END; i++ ) {

				n = this.heap[i];
				k = n.obj[key_prop];

				if ( k > n.key ) {
					n.key = k;
					this.pushDown( i, n );
				} else if ( k < n.key ) {
					n.key = k;
					this.pushUp( i, n );
				} // End-if.

			} // End for-loop.

		} // End function updateAllKeys()

		public function getHeapVector():Vector.<StructNode> {
			return this.heap;
		} // End function getHeapVector()

		/**
		 * Used for debugging only.
		 */
		public function toString():String {
			return this.heap.toString();
		} // End function toString()

	} // End class BinaryHeap

} // End package