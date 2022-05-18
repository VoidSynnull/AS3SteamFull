package game.scenes.lands.shared.tileLib.generation.generators {

	/**
	 * Similar to the tunnel generator but uses a different sort of algorithm to produce
	 * branches of a given terrain type.
	 * 
	 * 
	 * -- ive changed the TileBranch class so many times, this generator should be assumed
	 * broken until this top message is removed. i.e. forever.
	 */

	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.classes.TileDirection;
	import game.scenes.lands.shared.tileLib.generation.data.TileBranch;
	
	public class BranchGenerator extends MapGenerator {

		// tile type of the vein.
		public var veinType:uint = 4;
		
		/**
		 * maximum number of distinct branch starting points - the roots of the different branches.
		 */
		public var maxRoots:int = 6;

		public var maxBranchLen:int = 16;
		public var minBranchLen:int = 4;

		public var maxBranches:int = 8;

		/**
		 * probability that a branch will continue moving forward
		 */
		public var forwardChance:Number = 0.8;

		/**
		 * if a branch does NOT go forward, the probability that the branch will
		 * take a soft turn left or right. If this fails the branch will
		 * take a hard turn.
		 */
		public var softTurnChance:Number = 0.8;

		/**
		 * probability at each step that a branch will spawn a sub-branch.
		 */
		public var branchSpawnChance:Number = 0.3;

		public function BranchGenerator( tmap:TileMap ) {

			super( tmap );
			
		} // CaveGenerator()
		
		override public function generate( gameData:LandGameData=null ):void {

			this.randomMap = gameData.worldRandoms.randMap;
			
			var branches:Vector.<TileBranch> = new Vector.<TileBranch>();

			// seed the branches.
			var count:int = Math.random()*this.maxRoots;
			var tile:LandTile;
			while ( branches.length < count ) {

				branches.push(
					new TileBranch( this.getRandDir(),
						this.randomMap.getRandom()*this.tileMap.rows,
						this.randomMap.getRandom()*this.tileMap.cols,
						this.minBranchLen + this.randomMap.getRandom()*(this.maxBranchLen-this.minBranchLen)
					) );

			} //

			var maxRow:int = this.tileMap.rows-1;
			var maxCol:int = this.tileMap.cols-1;

			var branch:TileBranch;
			var dir:int;
			var curLen:int;

			while ( branches.length > 0 ) {

				branch = branches.pop();
				curLen = 0;

				while ( curLen < branch.maxLen ) {

					this.tileMap.getTile( branch.row, branch.col ).type = this.veinType;

					if ( curLen > this.minBranchLen ) {

						dir = branch.direction;// = this.tryTurn( branch.direction );

						// try making a sub-branch.
						if ( this.randomMap.getRandom() < this.branchSpawnChance ) {
							branches.push( new TileBranch( this.getSubDir(dir), branch.row, branch.col, 0.75*(branch.maxLen - curLen)) );
						} //

					} //

					if ( dir < 4 && dir > 0 ) {
						if ( ++branch.col > maxCol ) {
							break;
						}
					} else if ( dir > 4 ) {
						if ( --branch.col < 0 ) {
							break;
						}
					}

					if ( dir == TileDirection.TOP_LEFT || dir == TileDirection.TOP || dir == TileDirection.TOP_RIGHT ) {
						if ( --branch.row < 0 ) {
							break;
						}
					} else if ( dir == TileDirection.BOTTOM_LEFT || dir == TileDirection.BOTTOM_RIGHT || dir == TileDirection.BOTTOM ) {
						if ( ++branch.row > maxRow ) {
							break;
						}
					} //

				} // end-if.

			} // end-while-loop.
			
		} // generate()

		private function getSubDir( dir:int ):int {
			
			var n:Number = this.randomMap.getRandom();
			if ( n > this.softTurnChance ) {
					
				// soft turn.
				if ( this.randomMap.getRandom() < 0.5 ) {
					return ( dir - 1 ) & 7;
				} else {
					return ( dir + 1 ) & 7;
				} //
					
			} else {
				// hard turn.
				if ( this.randomMap.getRandom() < 0.5 ) {
					return ( dir - 2 ) & 7;
				} else {
					return ( dir + 2 ) & 7;
				} //
			} //
			
		} //

		private function tryTurn( dir:int ):int {

			// try to turn.
			var n:Number = this.randomMap.getRandom();
			if ( n > this.forwardChance ) {

				// turn branch.
				n = this.randomMap.getRandom();
				if ( n > this.softTurnChance ) {

					// soft turn.
					if ( this.randomMap.getRandom() < 0.5 ) {
						return ( dir - 1 ) & 7;
					} else {
						return ( dir + 1 ) & 7;
					} //

				} else {
					// hard turn.
					if ( this.randomMap.getRandom() < 0.5 ) {
						return ( dir - 2 ) & 7;
					} else {
						return ( dir + 2 ) & 7;
					} //
				} //
				
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
		protected function getRandDir():int {

			return 8*Math.random();

		} // getRandDir()

	} // class
	
} // package