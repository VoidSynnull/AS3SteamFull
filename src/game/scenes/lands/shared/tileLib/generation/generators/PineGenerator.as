package game.scenes.lands.shared.tileLib.generation.generators {

	/**
	 * 
	 * Attempt to generate a pine tree. will it work?
	 * 
	 */
	import flash.utils.Dictionary;
	
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.classes.TileDirection;
	import game.scenes.lands.shared.tileLib.generation.data.TileBranch;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;

	public class PineGenerator extends MapGenerator {

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
		public var rootLandMap:String = "terrain";

		/**
		 * maximum number of distinct tree starting points - the roots of the different branches.
		 */
		public var maxRoots:int = 4;

		/**
		 * length before first branch and leaves.
		 */
		public var baseLength:Number = 5;

		public var minTreeHeight:int = 11;
		public var maxTreeHeight:int = 18;

		public var branchSpawnChance:Number = 0.4;

		public function PineGenerator( tset:TileSet=null ) {

			super( tset );
			
		} // CaveGenerator()
		
		override public function generate( gameData:LandGameData=null ):void {

			this.randomMap = gameData.worldRandoms.randMap;

			var branches:Vector.<TileBranch> = this.seedTrees( gameData.tileMaps );
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

			var curLen:int = 0;

			var leafCover:int;			// correct size of leaf cover for tree height.

			while ( curLen++ <= branch.maxLen ) {
				
				this.tileMap.fillTypeAt( branch.row, branch.col, this.trunkTile );

				if ( curLen >= this.baseLength ) {

					// always generate a branch right away.
					//branches.push( new TileBranch( this.getSubDir(branch), branch.row, branch.col, branch.depth+1, 2, 0.5*(branch.maxLen - curLen)) );

					if ( curLen >= 0.86*branch.maxLen ) {

						// thinner leaves at top of tree, no extra child branches.
						this.makeLeafRow( branch.col, branch.col, branch.row );

					} else {

						leafCover = 0.4*(branch.maxLen - curLen );

						this.makeLeafRow( branch.col-leafCover, branch.col+leafCover, branch.row );
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

				//dir = branch.direction = this.trySubTurn( branch.direction );
				// in the lamplight, the withered leaves collect at my feet
				//this.makeLeaves( branch.row, branch.col, 1 );

			} // while-loop.

		} // doSubBranch()

		/**
		 * create the initial tree branches that will be generated into trees.
		 */
		private function seedTrees( allMaps:Dictionary ):Vector.<TileBranch> {

			var branches:Vector.<TileBranch> = new Vector.<TileBranch>();
			var terrainMap:TileMap = allMaps[ this.rootLandMap ];

			// seed the branches.
			var count:int = Math.round(  this.randomMap.getRandom()*this.maxRoots );
			var tile:LandTile;

			var bRow:int, bCol:int;

			while ( count-- > 0 ) {

				// this is a bit complicated. find a tile from another set where there's already grass.
				// landType is the type where we're allowed to place trees.
				tile = this.getRandomWithType( terrainMap, this.rootLandType );
				if ( tile == null ) {
					continue;
				}

				// when converting between tile sets, there is always a chance that one tile set will extend further than the other.
				bRow = tile.row*(terrainMap.tileSize/this.tileSet.tileSize);
				if ( bRow >=  this.tileMap.rows ) {
					bRow = this.tileMap.rows-1;
				} //
				bCol = tile.col*(terrainMap.tileSize/this.tileSet.tileSize);
				if ( bCol >=  this.tileMap.cols ) {
					bCol = this.tileMap.cols-1;
				} //

				// check if another tree isn't being started nearby.
				if ( this.checkCollision( branches, bRow, bCol ) ) {
					continue;
				}

				if ( bRow < this.tileMap.rows-1 ) {
					bRow++;							// increment the column to 'root' the tree further into the ground.
				} //

				branches.push(
					new TileBranch( TileDirection.TOP, bRow, bCol, 0, this.minTreeHeight,
						this.minTreeHeight + this.randomMap.getRandom()*(this.maxTreeHeight-this.minTreeHeight)
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

		private function makeLeafRow( minCol:int, maxCol:int, row:int ):void {

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