package game.scenes.lands.shared.tileLib.generation.builders {

	/**
	 * builds one tree.
	 */
	
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.classes.TileDirection;
	import game.scenes.lands.shared.tileLib.generation.data.TileBranch;
	import game.scenes.lands.shared.tileLib.generation.data.TreeData;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;
	
	public class SmallTreeBuilder extends TreeBuilder {

		public var minBranchLen:int = 6;
		public var maxBranchLen:int = 10;

		//public var maxSubBranches:int = 5;

		/**
		 * probability that a branch will continue moving forward
		 */
		public var forwardChance:Number = 0.8;

		/**
		 * probability at each step that a branch will spawn a sub-branch.
		 */
		public var branchSpawnChance:Number = 0.3;

		public function SmallTreeBuilder( tset:TileSet=null ) {

			super( tset );
			
		} // CaveGenerator()

		override public function build( r:int, c:int, type:TreeData ):void {

			// no longer works until this.randomMap can get set.
			this.randomMap = null;
			
			var branches:Vector.<TileBranch> = new Vector.<TileBranch>();
			var branch:TileBranch = new TileBranch( TileDirection.TOP, r, c, 0, this.minBranchLen,
					this.minBranchLen + this.randomMap.getRandom()*(this.maxBranchLen-this.minBranchLen)
				);

			this.doRootBranch( branch, branches );

			while ( branches.length > 0 ) {

				this.doSubBranch( branches.pop(), branches );
				
			} // end-while-loop.

		} //

		/**
		 * root branches - the trunk of the tree - need slightly different rules from the sub-branches.
		 */
		private function doRootBranch( branch:TileBranch, branches:Vector.<TileBranch> ):void {

			var dir:int = branch.direction;
			var maxCol:int = this.tileMap.cols-1;

			var subs:int = 0;
			var curLen:int = 0;

			var tile:LandTile;

			while ( curLen++ <= branch.maxLen ) {

				//this.tileMap.getTile( branch.row, branch.col ).type |= this.trunkTile;
				
				tile = this.tileMap.getTile( branch.row, branch.col );
				if ( tile.type & this.trunkTile ) {
					break;
				} else {
					tile.type |= this.trunkTile;
				} //

				dir = branch.direction = this.tryTrunkTurn( branch.direction );

				if ( curLen == branch.minLen ) {

					// always generate a branch right away.
					branches.push( new TileBranch( this.getSubDir(branch), branch.row, branch.col, branch.depth+1, 2, 0.5*(branch.maxLen)) );
					subs++;

				} else  if ( curLen > branch.minLen ) {
					// try making a sub-branch.
					if ( this.randomMap.getRandom() < this.branchSpawnChance ) {
						branches.push( new TileBranch( this.getSubDir(branch), branch.row, branch.col, branch.depth+1, 2, 0.5*(branch.maxLen)) );
						subs++;
					} //
				}

				if ( dir < 4 && dir != 0 ) {			// right directions
					if ( ++branch.col > maxCol ) {
						break;
					}
				} else if ( dir > 4 ) {
					if ( --branch.col < 0 ) {
						break;
					}
				}
				
				if ( dir <= 1 || dir == 7 ) {			// up directions.
					if ( --branch.row < 0 ) {
						break;
					}
				} // note: no checking for 'down' directions on the root branch. trunk roots shouldn't go down.

			} // while-loop.

			if ( subs < 2 ) {
				if ( branch.row > 0 && branch.col > 0 && branch.row < this.tileMap.rows && branch.col < maxCol ) {
					branches.push( new TileBranch( this.getSubDir(branch), branch.row, branch.col, branch.depth+1, 2, 0.5*(branch.maxLen)) );
				}
			}

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
			var tile:LandTile;

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

				tile = this.tileMap.getTile( branch.row, branch.col );
				if ( (tile.type & this.trunkTile) != 0 ) {
					break;
				} else {
					tile.type |= this.trunkTile;
				} //

				//dir = branch.direction = this.trySubTurn( branch.direction );
				// in the lamplight, the withered leaves collect at my feet
				if ( curLen > 1 ) {
					this.makeLeaves( branch.row, branch.col, 3 );
				}

				// try making a sub-branch.
				if ( branch.maxLen > 3 && this.randomMap.getRandom() < this.branchSpawnChance ) {
					branches.push( new TileBranch( this.getSubDir(branch), branch.row, branch.col, branch.depth+1, 1, 0.5*(branch.maxLen)) );
				} //

			} // while-loop.

		} // doSubBranch()

		private function makeLeaves( row:int, col:int, radius:Number ):void {

			var r2:Number = radius*radius;
			var d2:Number;
			var rmax:int, cmax:int;

			if ( row + radius >= this.tileMap.rows ) {
				rmax = this.tileMap.rows - row - 1;
			} else {
				rmax = radius;
			}

			if ( col + radius >= this.tileMap.cols ) {
				cmax = this.tileMap.cols - col - 1;
			} else {
				cmax = radius;
			}

			// if row or col < radius then Math.max( -row ) > Math.max(-radius)
			for( var dr:int = Math.max( -row, -radius ); dr <= rmax; dr++ ) {

				for( var dc:int = Math.max( -col, -radius ); dc <= cmax; dc++ ) {

					d2 = dr*dr + dc*dc;
					if ( d2 <= r2 && this.randomMap.getRandom() > (d2/r2) ) { 
						this.tileMap.getTile( row + dr, col + dc ).type |= this.leafTile;
					} //

				} //

			} // for-loop.

		} // makeLeaves()

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
					return ( branch.direction - 1 ) & 7;
				} else {
					branch.nextBranch = TileDirection.LEFT;
					return ( branch.direction + 1 ) & 7;
				} //

			} //

			if ( branch.nextBranch == TileDirection.RIGHT ) {

				branch.nextBranch = TileDirection.LEFT
				return ( branch.direction + 1 ) & 7;

			} else {

				branch.nextBranch = TileDirection.RIGHT;
				return ( branch.direction - 1 ) & 7;

			} //

		} //

		/**
		 * the trunk should never turn too far horizontal, even if it would
		 * make interesting trees.
		 */
		private function tryTrunkTurn( dir:int ):int {

			// try to turn.
			var n:Number = this.randomMap.getRandom();
			if ( n > 0.9 ) {

				// soft turn.
				if ( this.randomMap.getRandom() < 0.5 ) {
					dir = ( dir - 1 ) & 7;
				} else {
					dir = ( dir + 1 ) & 7;
				} //
				
			} else {

				// turn towards center.
				return TileDirection.TOP;

			} //

			if ( dir == TileDirection.LEFT || dir == TileDirection.BOTTOM_LEFT ) {
				dir = TileDirection.TOP_LEFT;
			} else if ( dir == TileDirection.RIGHT || dir == TileDirection.BOTTOM_RIGHT ) {
				dir = TileDirection.TOP_RIGHT;
			} //

			return dir;

		} //

		private function trySubTurn( dir:int ):int {

			// try to turn.
			var n:Number = this.randomMap.getRandom();
			if ( n > this.forwardChance ) {

				// turn branch.
				//n = this.randomMap.getRandom();
				//if ( n > this.softTurnChance ) {

					// soft turn.
					if ( this.randomMap.getRandom() < 0.5 ) {
						return ( dir - 1 ) & 7;
					} else {
						return ( dir + 1 ) & 7;
					} //

				/*} else {
					// hard turn.
					if ( this.randomMap.getRandom() < 0.5 ) {
						return ( dir - 2 ) & 7;
					} else {
						return ( dir + 2 ) & 7;
					} //
				} //*/
				
			} //

			return dir;

		} //

	} // class
	
} // package