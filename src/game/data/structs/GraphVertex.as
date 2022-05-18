package game.data.structs {

	public class GraphVertex extends TopologyState {

		public var x:Number;
		public var y:Number;

		public var edges:Vector.<GraphEdge>;

		public var label:String;

		public function GraphVertex( nx:Number, ny:Number, str:String=null, edgeList:Vector.<GraphEdge>=null ) {

			this.x = nx;
			this.y = ny;

			if ( str != null ) {
				this.label = str;
			}

			if ( edgeList != null ) {
				this.edges = edgeList;
			} else {
				this.edges = new Vector.<GraphEdge>();
			}

		} //

		public function addEdge( e:GraphEdge ):void {

			this.edges.push( e );

		} //

	} // End Vertex

} // End package