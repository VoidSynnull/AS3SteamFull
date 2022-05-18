package game.scenes.lands.shared.tileLib.generation.builders {

	import flash.geom.Point;
	
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.generation.data.TreeData;
	import game.scenes.lands.shared.tileLib.generation.data.TreeLine;

	public class CactusBuilder extends TreeBuilder {

		private var trunkLen:int = 8;

		// height before first branches.
		private var baseHeight:int = 4;

		/**
		 * starting width of tree trunk.
		 */
		private var trunkWidth:Number = 2.5;

		private var minTreeScale:Number = 0.5;
		private var maxTreeScale:Number = 2;

		private var myScale:Number;

		/**
		 * how far the basic cactus arms extend from center of the cactus.
		 */
		private var armExtent:Number = 3.1;
		/**
		 * how far the basic cactus arms raise into the air.
		 */
		private var armHeight:Number = 3.25;

		public function CactusBuilder( tmap:TileMap ) {

			super( tmap );

		} // BigTreeBuilder

		public override function build( r:int, c:int, type:TreeData ):void {

			this.trunkTile = type.trunkTile;

			this.myScale = this.minTreeScale + ( this.maxTreeScale - this.minTreeScale )*this.randomMap.getRandom();

			var startPt:Point = new Point( (c+0.5), (r+0.5) );
			var endPt:Point = new Point( startPt.x, startPt.y - this.myScale*this.trunkLen );

			if ( endPt.y < 0 ) {
				endPt.y = 0;
			}

			var branch:TreeLine = new TreeLine();
			branch.setEndPoints( startPt, endPt, this.myScale*this.trunkWidth/2 );
			branch.endThickness = branch.halfThickness*0.4;

			// fill the main trunk.
			super.scanLineFillBranch( branch );

			this.makeCactusArms( branch );

		} //

		private function makeCactusArms( trunkBranch:TreeLine ):void {

			var side:int = 1;
			if ( this.randomMap.getRandom() < 0.5 ) {
				side = -1;
			}

			var r:int;

			var branch:TreeLine = new TreeLine();
			var startPt:Point = new Point();
			var endPt:Point = new Point();
			branch.setEndPoints( startPt, endPt, 1 );

			/**
			 * curLen counts the offset from the base (startRow) of the tree trunk.
			 * startRow - curLen is the current row in question.
			 */
			var curLen:int = this.baseHeight*this.myScale;
			if ( curLen < 2 ) {
				curLen = 2;
			} else if ( curLen > 6 ) {
				curLen = 6;
			}

			// percent of the distance from the top of the cactus. 100% is the top, 0% the bottom.
			var pct:Number;
			var length:Number = trunkBranch.length;

			/**
			 * if cactus arms are too close together on a given side, they can overlap and create a blob.
			 * this modulates when that happens.
			 */
			var nextLeft:int = curLen;
			var nextRight:int = curLen;

			// start from the base height and go up the tree.
			// dont make any branches too close to the top. along with not looking good, the cacti can look suggestive
			// if the first sub-branch spawns at the top.
			for( ; curLen < length-2; curLen++ ) {

				if ( side > 0 ) {
					if ( curLen < nextRight ) {
						continue;
					}
				} else {
					if ( curLen < nextLeft ) {
						continue;
					}
				} //

				pct = ( 1- Number(curLen / length) );
				branch.halfThickness = branch.endThickness = 0.4*trunkBranch.halfThickness*pct;
				//trace( "HALF THICKNESS: " + branch.halfThickness );
				if ( branch.halfThickness < 0.1 ) {
					return;
				}

				// start the branch outside the range of trunk thickness or the branch
				// will be swallowed up by the trunk itself.
				startPt.x = trunkBranch.startPt.x;
				startPt.y = trunkBranch.startPt.y - curLen;

				//trace( "START: " + branch.startPt );

				endPt.y = branch.startPt.y;
				endPt.x = branch.startPt.x + side*( pct*this.myScale*this.armExtent + 1 );

				branch.recompute();

				this.scanLineFillBranch( branch );

				if ( side > 0 ) {
					nextRight += 3*this.myScale;
				} else {
					nextLeft += 3*this.myScale;
				} //

				// dont always spawn an upwards branch.
				if ( this.randomMap.getRandom() < 0.5 ) {
					side = -side;
					continue;
				}

				// now from the previous branch, make an upwards branch, but push it out by 0.5.
				startPt.x = branch.endPt.x = branch.endPt.x + 0.5*side;
				startPt.y = branch.endPt.y;
				endPt.y = endPt.y - this.armHeight*pct*this.myScale;
				branch.recompute();

				this.scanLineFillBranch( branch );

				side = -side;

			} // end for-loop.

		} //

	} // class

} // package