package game.scenes.lands.shared.tileLib.generation.builders {

	import flash.geom.Point;
	
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.generation.data.TreeData;
	import game.scenes.lands.shared.tileLib.generation.data.TreeLine;

	public class BigTreeBuilder extends TreeBuilder {

		private var branchingHeight:int = 14;			// height of branching trees.
		private var regularHeight:int = 16;

		/**
		 * starting width of tree trunk.
		 */
		private var trunkWidth:Number = 3;

		private var minSpreadAngle:Number = 30*Math.PI/180;
		private var maxSpreadAngle:Number = 48*Math.PI/180;

		private var myScale:Number;

		private var minTreeScale:Number = 0.5;
		private var maxTreeScale:Number = 2.5;

		public function BigTreeBuilder( tmap:TileMap ) {

			super( tmap );

		} // BigTreeBuilder

		override public function build( r:int, c:int, type:TreeData ):void {

			this.leafTile = type.leafTile;
			this.trunkTile = type.trunkTile;

			this.myScale = this.minTreeScale + ( this.maxTreeScale - this.minTreeScale )*this.randomMap.getRandom();

			if ( type.type == "branch" ) {
				this.buildBranching( r, c );
			} else {
				this.buildRegular( r, c );
			}

		} //

		/**
		 * these things are confusing to look at. the line-drawing method can do much more
		 * than the old method, but is more complicated.
		 */
		public function buildRegular( r:int, c:int ):void {

			var branches:Vector.<TreeLine> = new Vector.<TreeLine>();

			var startPt:Point = new Point( (c+0.5), (r+0.5) );
			var endPt:Point = new Point( startPt.x, startPt.y - this.myScale*this.regularHeight );

			// the intial trunk branch.
			var branch:TreeLine = new TreeLine();
			branch.setEndPoints( startPt, endPt, this.trunkWidth/2 );
			branch.endThickness = branch.halfThickness*0.2;

			this.scanLineFillBranch( branch );
			this.fillCircle( endPt.y, endPt.x, 3, this.leafTile );			// leaves
			this.branchFractal( branch, branches );

			while ( branches.length > 0 ) {

				branch = branches.shift();

				if ( branch.length > 10 ) {
					this.branchFractal( branch, branches );
				}
				this.scanLineFillBranch( branch );
				this.fillCircle( branch.endPt.y, branch.endPt.x, 5, this.leafTile );			// leaves
				
			} //

		} //

		/**
		 * dont think this is even used right now. this is a tree that branches in 2 at the end
		 * of every sub-branch - other trees branch randomly along the length of the branch.
		 */
		public function buildBranching( r:int, c:int ):void {

			var branches:Vector.<TreeLine> = new Vector.<TreeLine>();

			var startPt:Point = new Point( (c+0.5), (r+0.5) );
			var endPt:Point = new Point( startPt.x, startPt.y - this.myScale*this.branchingHeight );

			var branch:TreeLine = new TreeLine();
			branch.setEndPoints( startPt, endPt, this.trunkWidth/2 );

			this.scanLineFillBranch( branch );
			this.branchAtTop( branch, branches );

			while ( branches.length > 0 ) {

				branch = branches.shift();

				if ( branch.length > 4 ) {
					this.branchAtTop( branch, branches );
				}
				this.scanLineFillBranch( branch );
				this.fillCircle( branch.endPt.y, branch.endPt.x, 2, this.leafTile );			// leaves

			} //

		} //

		/**
		 * makes sub-branches along each side of the branch.
		 */
		public function branchFractal( branch:TreeLine, branches:Vector.<TreeLine> ):void {

			// starting point of the new branch as a percentage along the old branch.
			var t:Number = 0.25 + 0.1*this.randomMap.getRandom();

			var startPt:Point = branch.startPt;
			var endPt:Point = branch.endPt;

			var dx:Number = branch.dx;
			var dy:Number = branch.dy;

			var b:TreeLine;
			var p0:Point;
			var p1:Point;

			// causes branches to switch from side to side.
			var side:int = 1;
			if ( this.randomMap.getRandom() < 0.5 ) {
				side = -1;
			}

			while ( t < 1 ) {

				var angle:Number = ( this.minSpreadAngle + this.randomMap.getRandom()*(this.maxSpreadAngle-this.minSpreadAngle) );
				angle *= side;
				side = -side;

				var cos:Number = 0.4*branch.length*Math.cos( angle );
				var sin:Number = 0.4*branch.length*Math.sin( angle );

				p0 = new Point( (1-t)*startPt.x + t*endPt.x, (1-t)*startPt.y + t*endPt.y );

				// cos terms are the terms due to the continuation of the previous branch.
				// sin terms are the terms due to the normal vector.
				p1 = new Point( p0.x + cos*dx - dy*sin, p0.y + cos*dy + sin*dx );

				b = new TreeLine();
				b.setEndPoints( p0, p1, 0.5 );
				branches.push( b );

				t += 0.2 + 0.2*this.randomMap.getRandom();

			} //

		} //

		/**
		 * makes a new set of branches at the very end of a tree branch.
		 */
		private function branchAtTop( branch:TreeLine, branches:Vector.<TreeLine> ):void {

			var dx:Number = branch.dx;
			var dy:Number = branch.dy;
			
			var prevPt:Point = branch.endPt;

			var angle:Number = -( this.minSpreadAngle + this.randomMap.getRandom()*(this.maxSpreadAngle-this.minSpreadAngle) );

			var cos:Number = 0.6*branch.length*Math.cos( angle );
			var sin:Number = 0.6*branch.length*Math.sin( angle );

			// cos terms are the terms due to the continuation of the previous branch.
			// sin terms are the terms due to the normal vector.
			var endPt:Point = new Point( prevPt.x + cos*dx - dy*sin, prevPt.y + cos*dy + sin*dx );

			var thick:Number = branch.halfThickness*0.4;

			var sub:TreeLine = new TreeLine();
			sub.setEndPoints( prevPt, endPt, thick );
			branches.push( sub );

			angle = ( this.minSpreadAngle + this.randomMap.getRandom()*(this.maxSpreadAngle-this.minSpreadAngle) );
			cos = 0.6*branch.length*Math.cos( angle );
			sin = 0.6*branch.length*Math.sin( angle );

			endPt = new Point( prevPt.x + cos*dx - dy*sin, prevPt.y + cos*dy + sin*dx );

			sub = new TreeLine();
			sub.setEndPoints( prevPt, endPt, thick );
			branches.push( sub );

		} //

	} // class

} // package