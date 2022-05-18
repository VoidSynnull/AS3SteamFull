package game.scenes.lands.shared.tileLib.generation.builders {

	/**
	 * 
	 * Attempt to generate a pine tree. will it work?
	 * 
	 */

	import game.scenes.lands.shared.tileLib.classes.TileDirection;
	import game.scenes.lands.shared.tileLib.generation.data.TileBranch;
	import game.scenes.lands.shared.tileLib.generation.data.TreeData;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;

	public class SmallPineBuilder extends TreeBuilder {

		/**
		 * length before first branch and leaves.
		 */
		public var baseLength:Number = 5;

		public var minTreeHeight:int = 11;
		public var maxTreeHeight:int = 18;

		public var branchSpawnChance:Number = 0.4;

		public function SmallPineBuilder( tset:TileSet ) {

			super( tset );

		} //

		override public function build( r:int, c:int, type:TreeData ):void {

			this.randomMap = this.tileSet.randoms.randMap;

			var branches:Vector.<TileBranch> = new Vector.<TileBranch>();
			var branch:TileBranch = new TileBranch( TileDirection.TOP, r, c, 0, this.minTreeHeight,
					this.minTreeHeight + this.randomMap.getRandom()*(this.maxTreeHeight-this.minTreeHeight)
				);

			this.doRootBranch( branch, branches );

			while ( branches.length > 0 ) {

				this.doSubBranch( branches.pop(), branches );

			} // end-while-loop.

		} // generate()

		/**
		 * root branches - the trunk of the tree - need slightly different rules from the sub-branches.
		 */
		private function doRootBranch( branch:TileBranch, branches:Vector.<TileBranch> ):void {

			var dir:int = branch.direction;
			var maxCol:int = this.tileMap.cols-1;

			var curLen:int = 0;

			var leafCover:int;			// correct size of leaf cover for tree height.

			while ( curLen++ <= branch.maxLen ) {
				
				this.tileMap.fillTypeAt( branch.row, branch.col, this.trunkTile );

				if ( curLen >= this.baseLength ) {

					// always generate a branch right away.
					//branches.push( new TileBranch( this.getSubDir(branch), branch.row, branch.col, branch.depth+1, 2, 0.5*(branch.maxLen - curLen)) );

					if ( curLen >= 0.86*branch.maxLen ) {

						// thinner leaves at top of tree, no extra child branches.
						this.fillLeafRow( branch.col, branch.col, branch.row );

					} else {

						// leaf cover decreases as you go up the tree.
						leafCover = 0.4*(branch.maxLen - curLen );

						this.fillLeafRow( branch.col-leafCover, branch.col+leafCover, branch.row );
						if ( (curLen % 2)==0 ) {

							branches.push(
								new TileBranch( this.getSubDir(branch), branch.row, branch.col, branch.depth+1, 2, leafCover )
							);

						} //
					}

				} //

				// for now, pine trees will only grow upwards.
				if ( --branch.row < 0 ) {
					break;
				}

			} // while-loop.

		} // doRootBranch()

		/**
		 * sub-branches have slightly different rules from the main trunk, such as leaf positioning and
		 * allowed directions for the branch.
		 */
		private function doSubBranch( branch:TileBranch, branches:Vector.<TileBranch> ):void {

			var dir:int = branch.direction;
			var maxRow:int = this.tileMap.rows-1;
			var maxCol:int = this.tileMap.cols-1;

			var curLen:int = 0;

			while ( curLen++ <= branch.maxLen ) {

				if ( dir < 4 && dir > 0 ) {				// right directions
					if ( ++branch.col > maxCol ) {
						break;
					}
				} else if ( dir > 4 ) {					// left directions
					if ( --branch.col < 0 ) {
						break;
					}
				}
				
				if ( dir <= 1 || dir == 7 ) {			// up directions
					if ( --branch.row < 0 ) {
						break;
					}
				} else if ( dir >= 3 && dir <= 5 ) {	// down directions
					if ( ++branch.row > maxRow ) {
						break;
					}
				} //

				this.tileMap.fillTypeAt( branch.row, branch.col, this.trunkTile );
				this.tileMap.fillTypeAt( branch.row, branch.col, this.leafTile );

			} // while-loop.

		} // doSubBranch()

		/**
		 * checks if the given row,col is too close to another branch already being placed.
		 */
		private function checkCollision( branches:Vector.<TileBranch>, row:int, col:int, dist:int=2 ):Boolean {

			var b:TileBranch;

			for( var i:int = branches.length-1; i >= 0; i-- ) {

				b = branches[i];
				if ( Math.abs(row-b.row) <= dist && Math.abs(col-b.col) <= dist ) {
					return true;
				}

			} //

			return false;

		} //

		private function fillLeafRow( minCol:int, maxCol:int, row:int ):void {

			if ( minCol < 0 ) {
				minCol = 0;
			}
			if ( maxCol >= this.tileMap.cols ) {
				maxCol = this.tileMap.cols - 1;
			}

			for( var c:int = minCol; c <= maxCol; c++ ) {
				this.tileMap.getTile( row, c ).type |= this.leafTile;
			} //

		} //

		/**
		 * Get a direction for a branch's subtree.
		 * 
		 * In all the directions I use an &7 to perform a %8. Oddly this works properly with negative
		 * mods, whereas the default mod operator does not. Complete accident.
		 */
		private function getSubDir( branch:TileBranch ):int {

			if ( branch.nextBranch == 0 ) {

				// pick random - left or right.
				var n:Number = this.randomMap.getRandom();
				if ( n < 0.5 ) {
					branch.nextBranch = TileDirection.RIGHT;
					return TileDirection.LEFT;
				} else {
					branch.nextBranch = TileDirection.LEFT;
					return TileDirection.RIGHT;
				} //

			} //

			if ( branch.nextBranch == TileDirection.RIGHT ) {

				branch.nextBranch = TileDirection.LEFT;
				return TileDirection.RIGHT;

			} else {

				branch.nextBranch = TileDirection.RIGHT;
				return TileDirection.LEFT;

			} //

		} // getSubDir()

	} // class
	
} // package