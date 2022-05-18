package game.data.structs {

	import flash.display.MovieClip;

	public class GraphUtils {

		/**
		 * Indicates an edge that forms a directed connection between its vertices.
		 */
		static public const DirectedEdge:String = "d";
		static public const NormalEdge:String = "_";

		public function GraphUtils() {
		} //

		/**
		 * Converts subclips contained in a movieclip into a graph data object.
		 * 
		 * subclips of the 'clip' are converted by the following rules:
		 * 1) clips labelled with the vertex prefix -> v0,v1,v2, etc are converted into vertices of the graph.
		 * 2) clips labelled with the edge prefix, followed by indices separated by '_' or 'd' are converted into edges
		 * between the corresponding vertices.
		 * example: e3_2 represents an edge joining vertices with indices 3 and 2.
		 * e3->2 represents a one-way edge joining vertex 3 to 2, but not the other way around.
		 *
		 * 
		 */
		static public function convertClipsToGraph( clip:MovieClip,
			vertexPrefix:String="v", edgePrefix:String="e", removeClips:Boolean=true ):Graph {

			var vertices:Vector.<GraphVertex> = new Vector.<GraphVertex>();
			var g:Graph = new Graph( vertices );

			var i:int = 0;
			var mc:MovieClip = clip[ vertexPrefix + i ];

			while ( mc != null ) {

				vertices.push( new GraphVertex( mc.x, mc.y, mc.name ) );

				if ( removeClips == true ) {
					clip.removeChild( mc );
				}

				i++;
				mc = clip[ vertexPrefix + i ];

			} // end-while.

			var len:int = vertices.length;
			if ( len == 0 ) {
				// any edges now would be an error.
				return g;
			}

			var indexStart:int;				// start of the index in the edge string.

			for( var s:String in clip ) {

				if ( s.indexOf( edgePrefix ) != 0 ) {			// only looking for edges.
					continue;
				}
				mc = clip[ s ];
				if ( removeClips == true ) {
					clip.removeChild( mc );
				}

				indexStart = s.indexOf( NormalEdge );
				if ( indexStart > 0 ) {

					GraphUtils.joinByDistance( g, g.getVertex( int( s.slice( edgePrefix.length, indexStart )) ),
						g.getVertex( int( s.slice( indexStart + NormalEdge.length ) ) ), false );

				} else {

					// find indices of directed edge
					indexStart = s.indexOf( DirectedEdge );
					GraphUtils.joinByDistance( g, g.getVertex( int( s.slice( edgePrefix.length, indexStart )) ),
						g.getVertex( int( s.slice( indexStart + DirectedEdge.length ) ) ), true );

				} //

			} // end for-loop.

			return g;

		} //

		/**
		 * Join two vertices in a graph with an edge cost equal to their euclidean distance.
		 */
		public static function joinByDistance( g:Graph, v1:GraphVertex, v2:GraphVertex, directed:Boolean=false ):void {

			var dx:Number = v1.x - v2.x;
			var dy:Number = v2.y - v2.y;

			if ( directed ) {

				g.joinDirectedVertices( v1, v2, Math.sqrt( dx*dx + dy*dy ) );

			} else {

				g.joinVertices( v1, v2, Math.sqrt( dx*dx + dy*dy ) );

			} //

		} //

	} // End GraphUtils

} // End package