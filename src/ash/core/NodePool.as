package ash.core
{
	import flash.utils.Dictionary;
	/**
	 * This internal class maintains a pool of deleted nodes for reuse by the framework. This reduces the overhead
	 * from object creation and garbage collection.
	 * 
	 * Because nodes may be deleted from a NodeList while in use, by deleting Nodes from a NodeList
	 * while iterating through the NodeList, the pool also maintains a cache of nodes that are added to the pool
	 * but should not be reused yet. They are then released into the pool by calling the releaseCache method.
	 */
	internal class NodePool
	{
		private var nodePool:Array = [];
		private var nodeCache:Array = [];
		private var nodeClass : Class;
		private var components : Dictionary;

		/**
		 * Creates a pool for the given node class.
		 */
		public function NodePool( nodeClass : Class, components : Dictionary )
		{
			this.nodeClass = nodeClass;
			this.components = components;
		}

		/**
		 * Fetches a node from the pool.
		 */
		internal function get() : Node
		{
			if ( this.nodePool.length )
			{
				return this.nodePool.pop();
			}
			else
			{
				return new nodeClass();
			}
		}

		/**
		 * Adds a node to the pool.
		 */
		internal function dispose( node : Node ) : void
		{
			for each( var componentName : String in components )
			{
				node[ componentName ] = null;
			}
			node.entity = null;
			node.next = null;
			node.previous = null;
			this.nodePool.push(node);
		}
		
		/**
		 * Adds a node to the cache
		 */
		internal function cache( node : Node ) : void
		{
			this.nodeCache.push(node);
		}
		
		/**
		 * Releases all nodes from the cache into the pool
		 */
		internal function releaseCache() : void
		{
			while(this.nodeCache.length)
			{
				dispose( this.nodeCache.pop() );
			}
		}
	}
}
