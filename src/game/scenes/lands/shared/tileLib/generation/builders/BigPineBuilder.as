package game.scenes.lands.shared.tileLib.generation.builders {

	import flash.geom.Point;
	
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.generation.data.TreeData;
	import game.scenes.lands.shared.tileLib.generation.data.TreeLine;

	public class BigPineBuilder extends TreeBuilder {

		private var trunkLen:int = 17;

		// height before first branches.
		private var baseHeight:int = 6;

		/**
		 * starting width of tree trunk.
		 */
		private var trunkWidth:Number = 2.5;

		private var minTreeScale:Number = 0.5;
		private var maxTreeScale:Number = 2.5;

		private var myScale:Number;

		public function BigPineBuilder( tmap:TileMap ) {

			super( tmap );

		} // BigTreeBuilder

		public override function build( r:int, c:int, type:TreeData ):void {

			this.leafTile = type.leafTile;
			this.trunkTile = type.trunkTile;

			this.myScale = this.minTreeScale + ( this.maxTreeScale - this.minTreeScale )*this.randomMap.getRandom();

			var startPt:Point = new Point( (c+0.5), (r+0.5) );
			var endPt:Point = new Point( startPt.x, startPt.y - this.myScale*this.trunkLen );

			if ( endPt.y < 0 ) {
				endPt.y = 0;
			}

			var branch:TreeLine = new TreeLine();
			branch.setEndPoints( startPt, endPt, this.myScale*this.trunkWidth/2 );
			branch.endThickness = branch.halfThickness*0.1;

			// fill some leaves at the very top of the tree.
			this.tileMap.getTile( endPt.y, endPt.x ).type |= this.leafTile;
			//this.fillLeafRow( endPt.x, endPt.x, endPt.y );			// this would be used if you want more than 1 leaf filled at the very top.

			// fill the main trunk.
			super.scanLineFillBranch( branch );

			// creates sporadic branches and the pine leaves throughout the tree.
			this.fillPineTree( branch.startPt.x, branch.startPt.y, branch.length );

		} //

		private function fillPineTree( col:int, startRow:int, length:Number ):void {

			// amount leaves ( and hence branches ) extend on both sides of the tree
			// for the given height.
			var leafCover:int;

			var side:int = 1;
			if ( this.randomMap.getRandom() < 0.5 ) {
				side = -1;
			}

			var branchMod:int = 2*this.myScale;
			if ( branchMod < 2 ) {
				branchMod = 2;
			}

			var r:int;

			var curLen:int = this.baseHeight*this.myScale;
			if ( curLen < 4 ) {
				curLen = 4;
			} else if ( curLen > 8 ) {
				curLen = 8;
			}

			// start from the base height and go up the tree.
			for( ; curLen < length; curLen++ ) {

				r = startRow - curLen;

				if ( curLen >= 0.86*length ) {

					this.fillLeafRow( col, col, r );

				} else {

					// leaf cover decreases as you go up the tree.
					leafCover = 0.4*( length - curLen ) -myScale*this.randomMap.getRandom();
					if ( leafCover < 2 ) {
						leafCover = 2;
					}

					if ( curLen % branchMod == 0 ) {
						// create a branch.
						this.boundedLine( col, r, col + side*leafCover, r, this.trunkTile | this.leafTile );
						side = -side;

					} else {

						this.fillLeafRow( col - leafCover, col + leafCover, r );

					} //

				} // end-if.

			} // end for-loop.

		} //

		protected override function drawScanLine( x0:int, x1:int, y:int, type:uint ):void {

			var tile:LandTile;
			var row:Vector.<LandTile> = this.tileMap.getTiles()[y];

			if ( x0 < x1 ) {

				while ( x0 <= x1 ) {

					tile = row[x0++];
					tile.type |= type;

				} //

			} else {

				while( x1 <= x0 ) {

					tile = row[x1++];
					tile.type |= type;

				} //

			} //

		} // drawScanLine()

	} // class

} // package