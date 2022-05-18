package game.scenes.lands.shared.tileLib.generation.data {

	/**
	 * class used to generate different terrain features that branch off
	 * in multiple directions.
	 */
	public class TileBranch {

		// current direction branch was moving.
		public var direction:int;

		// lead location of the branch. new branches are generated from this point.
		public var row:int;
		public var col:int;

		public var maxLen:int;
		public var minLen:int;

		/**
		 * direction of the last branch. can be used to prevent repetition.
		 */
		public var nextBranch:int;

		/**
		 * depth is how many branches from a root this branch is.
		 * depth==0 means the branch is the first of its tree/tunnel/ore vein/whatever
		 */
		public var depth:int;

		/**
		 * next_dir is the preferred direction of the next branch.
		 */
		public function TileBranch( branchDir:int, r:int, c:int, depth:int=0, len_min:int=1, len_max:int=10 ) {

			this.maxLen = len_max;
			this.minLen = len_min;

			this.depth = depth;

			this.direction = branchDir;

			this.row = r;
			this.col = c;

		} // TileBranch()

	} // class

} // package