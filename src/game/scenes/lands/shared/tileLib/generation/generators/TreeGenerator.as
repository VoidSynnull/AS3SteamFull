package game.scenes.lands.shared.tileLib.generation.generators {

	/**
	 * 
	 * NOT CURRENTLY USED. THIS CLASS IS OUT OF DATE and should possibly be deleted.
	 * 
	 * Tree generator is like a branch generator with more specific rules for directions/placement.
	 * 
	 */
	import flash.utils.Dictionary;
	
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.classes.TileDirection;
	import game.scenes.lands.shared.tileLib.generation.data.TileBranch;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;
	
	public class TreeGenerator extends MapGenerator {

		// tile type of the vein.
		public var trunkTile:uint = 0x000100;
		public var leafTile:uint = 0x000200;

		/**
		 * terrain type that the tree can be rooted in. currently 'grass'
		 * maybe change this to refer to the NAME of a terrain? seems safer.
		 */
		public var rootLandType:uint = 4;
		/**
		 * rootLandSet is the name of the tile set that contains the root land type.
		 */
		public var rootLandSet:String = "terrain";

		/**
		 * maximum number of distinct tree starting points - the roots of the different branches.
		 */
		public var maxRoots:int = 4;

		public var minBranchLen:int = 6;
		public var maxBranchLen:int = 10;

		//public var maxSubBranches:int = 5;

		/**
		 * probability that a branch will continue moving forward
		 */
		public var forwardChance:Number = 0.8;

		/**
		 * if a branch does NOT go forward, the probability that the branch will
		 * take a soft turn left or right. If this fails the branch will
		 * take a hard turn.
		 */
		//public var softTurnChance:Number = 0.8;

		/**
		 * probability at each step that a branch will spawn a sub-branch.
		 */
		public var branchSpawnChance:Number = 0.3;

		public function TreeGenerator( tset:TileSet=null ) {

			super( tset );
			
		} // CaveGenerator()
		
		override public function generate( gameData:LandGameData=null ):void {

			this.randomMap = this.tileSet.randoms.randMap;

			var branches:Vector.<TileBranch> = this.seedTrees( gameData.tileSets );
			var branch:TileBranch;

			while ( branches.length > 0 ) {

				branch = branches.pop();

				if ( branch.depth == 0 ) {
					this.doRootBranch( branch, branches );
				} else {
					this.doSubBranch( branch, branches );
				}

			} // end-while-loop.
			
		} // generate()

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
					} //
					subs++;

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

			//trace( "subs: " + subs );

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
				if ( tile.type & this.trunkTile ) {
					break;
				} else {
					tile.type |= this.trunkTile;
				} //

				//dir = branch.direction = this.trySubTurn( branch.direction );
				// in the lamplight, the withered leaves collect at my feet
				this.makeLeaves( branch.row, branch.col, 3 );

				// try making a sub-branch.
				if ( branch.maxLen > 3 && this.randomMap.getRandom() < this.branchSpawnChance ) {
					branches.push( new TileBranch( this.getSubDir(branch), branch.row, branch.col, branch.depth+1, 1, 0.5*(branch.maxLen)) );
				} //
				
			} // while-loop.

		} // doSubBranch()

		/**
		 * create the initial tree branches that will be generated into trees.
		 */
		private function seedTrees( allSets:Dictionary ):Vector.<TileBranch> {

			var branches:Vector.<TileBranch> = new Vector.<TileBranch>();
			var terrainSet:TileSet = allSets[ this.rootLandSet ];

			// seed the branches.
			var count:int = Math.round(  this.randomMap.getRandom()*this.maxRoots );
			var tile:LandTile;

			var bRow:int, bCol:int;

			while ( count-- > 0 ) {
				
				// this is a bit complicated. find a tile from another set where there's already grass.
				// landType is the type where we're allowed to place trees.
				tile = this.getRandomWithType( terrainSet.tileMap, this.rootLandType );
				if ( tile == null ) {
					continue;
				}

				bRow = tile.row*(terrainSet.tileSize/this.tileSet.tileSize);
				if ( bRow >=  this.tileMap.rows ) {
					bRow = this.tileMap.rows-1;
				} //
				bCol = tile.col*(terrainSet.tileSize/this.tileSet.tileSize);
				if ( bCol >=  this.tileMap.cols ) {
					bCol = this.tileMap.cols-1;
				} //

				if ( this.isNonEmptyInRect( bRow-1, bRow+1, bCol-2, bCol+2, this.tileMap ) ) {
					continue;
				}

				/*// check that another tree isn't being started nearby.
				if ( this.checkCollision( branches, bRow, bCol ) ) {
					continue;
				}*/

				if ( bRow < this.tileMap.rows-1 ) {
					bRow++;							// increment the row to 'root' the tree further into the ground.
				} //

				branches.push(
					new TileBranch( TileDirection.TOP, bRow, bCol, 0, this.minBranchLen,
						this.minBranchLen + this.randomMap.getRandom()*(this.maxBranchLen-this.minBranchLen)
					) );

			} //

			return branches;

		} // seedTrees()

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

		/**
		 * get a random tile direction. one of the four tile points or a combination of them in
		 * the case of diagonals.
		 * 
		 * i checked the probabilities and the odds of each diretion are equal, providing
		 * the map random function is fair.
		 */
		/*protected function getRandDir():int {
		} // getRandDir()*/

	} // class
	
} // package