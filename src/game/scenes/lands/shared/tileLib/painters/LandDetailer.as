package game.scenes.lands.shared.tileLib.painters {

	/**
	 * Copies small detail bitmaps onto a larger bitmap at random points along a line.
	 * 
	 * Used to draw little details - rocks, grass, leaves etc. onto curves of the land or trees.
	 * 
	 * All the drawing needs to be repeatable - with the same starting perlin map,
	 * you should get the same results every time, no matter what order you draw
	 * the lines in.
	 */

	/**
	 * Ugh note:
	 * 
	 * Land details cannot be drawn to bitmap while the line stroke is being drawn because the final paint-fill
	 * and land hilight will cover them up. Instead they need to be put in a queue and drawn after the rest
	 * of the view has been drawn to the bitmap.
	 * 
	 */
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.classes.DetailType;
	import game.scenes.lands.shared.tileLib.classes.RandomMap;

	public class LandDetailer {

		/**
		 * Movieclip whose different frames store the details to be placed on the ground.
		 * This and ceilingDetails used to be vectors of display objects, but I changed to a single movieclip
		 * to avoid loading a large number of tiny detail files.
		 */
		private var topClip:MovieClip;
		private var sideClip:MovieClip;
		private var bottomClip:MovieClip;

		/**
		 * detail objects for the current tile type. they reference the top,side,bottom clips which are only stored
		 * separately for speed.
		 */
		private var topDetail:DetailType;
		private var sideDetail:DetailType;
		private var bottomDetail:DetailType;

		private var randMap:RandomMap;

		/**
		 * Tracks details that need to be drawn to the bitmap once the current painting operation is complete.
		 */
		private var drawQueue:Vector.<LandDetail>;

		/**
		 * Matrix for drawing line details.
		 */
		private var matrix:Matrix;

		/**
		 * used to get current tile information.
		 */
		private var context:RenderContext;

		/**
		 * if true, details are sorted in painter-canvas order ( by y-value ) before being drawn.
		 * this is necessary for objects on terrain but pointless for leaves.
		 */
		public var sortDetails:Boolean = true;

		/**
		 * used for bounds intersection tests.
		 */
		//private var hitRect:Rectangle;

		// details per edge can be edited by xml. I guess.
		//private var detailsPerEdge:int;

		public function LandDetailer( randMap:RandomMap, groundObjects:MovieClip=null, ceilingObjects:MovieClip=null ) {

			this.matrix = new Matrix();
			//this.hitRect = new Rectangle();

			if ( groundObjects ) {

				this.topClip = groundObjects;
				groundObjects.stop();

			} //

			if ( ceilingObjects ) {
				this.bottomClip = ceilingObjects;
				ceilingObjects.stop();
			}

			this.randMap = randMap;

			this.drawQueue = new Vector.<LandDetail>();

		} //

		public function hasDetails():Boolean {
			return ( this.drawQueue.length > 0 );
		}

		public function setDetailClips( detailTypes:Dictionary ):void {

			if ( detailTypes != null ) {

				var detail:DetailType;

				detail = detailTypes[ LandTile.TOP ];
				if ( detail ) {
					this.topClip = detail.clip;
					this.topDetail = detail;
				} else {
					this.topClip = null;
				}

				detail = detailTypes[ LandTile.BOTTOM ];
				if ( detail ) {
					this.bottomClip = detail.clip;
					this.bottomDetail = detail;
				} else {
					this.bottomClip = null;
				}

				detail = detailTypes[ LandTile.LEFT ];
				if ( detail ) {
					this.sideClip = detail.clip;
					this.sideDetail = detail;
				} else {
					this.sideClip = null;
				}

			} else {
				this.topClip = this.bottomClip = this.sideClip = null;
			}

		} //

		/**
		 * pick random t's in [0,1] along the line and draw images at those locations.
		 * 
		 * note that all the drawing details have to be perfectly repeatable:
		 * when you draw the same curve over again with the same perlin noise pattern,
		 * the same details need to be drawn in exactly the same locations.
		 * 
		 */
		public function makeTopDetails( startPt:Point, ctrlPt:Point, endPt:Point ):void {

			if ( !this.topClip ) {
				return;
			}

			/*// give a chance to skip the details entirely.
			if ( (n&0xFF) < 150 ) {
				return;
			}*/

			// parametric t determines where on the line to put the detail.
			var t:Number;

			var x:Number = ctrlPt.x;
			var y:Number = ctrlPt.y;

			var angle:Number;

			var count:int = Math.round(
					this.topDetail.minDetails + (this.topDetail.maxDetails - this.topDetail.minDetails) *
						( ( this.randMap.getIntAt( 3*x, 5*y )&0xFF) / 0x100 )
						);

			if ( count <= 0 ) {
				return;
			}

			var rate:Number = Number( 1 / count );

			// count is pre-incremented to get the rate computation correct.
			while ( --count >= 0 ) {

				t = rate*( count + this.randMap.getNumberAt( 2*x, 7*y ) );

				/**
				 * get the point at percent t according to the bezier curve equation.
				 */
				x = t*( t*endPt.x ) + (1-t)*( 2*t*ctrlPt.x + (1-t)*startPt.x );
				y = t*( t*endPt.y ) + (1-t)*( 2*t*ctrlPt.y + (1-t)*startPt.y );

				angle = Math.atan2( t*(endPt.y-ctrlPt.y) + (1-t)*(ctrlPt.y-startPt.y), t*(endPt.x-ctrlPt.x) + (1-t)*(ctrlPt.x-startPt.x) );

				// use a random detail image. the final parameter here is a pseudo-randomly chosen detail index.
				// if too slow, these land detail objects should be stored in a pool.
				this.drawQueue.push( new LandDetail( this.topClip, x, y, angle, this.topClip.totalFrames*this.randMap.getNumberAt(5*x,3*y)+1, y ) );

			} // while-loop

		} //

		public function makeBottomDetails( startPt:Point, ctrlPt:Point, endPt:Point ):void {

			if ( !this.bottomClip ) {
				return;
			}

			var t:Number;

			var x:Number = ctrlPt.x;
			var y:Number = ctrlPt.y;

			var angle:Number;
			
			var count:int = Math.round(
				this.topDetail.minDetails + (this.topDetail.maxDetails - this.topDetail.minDetails) *
				( ( this.randMap.getIntAt( 3*y, 3*x )&0xFF) / 0x100 )
			);
			
			if ( count <= 0 ) {
				return;
			}
			var rate:Number = 1 / count;

			while ( --count >= 0 ) {

				t = rate*( count + this.randMap.getNumberAt( 10*x, 10*y ) );

				/**
				 * get the point at percent t according to the bezier curve equation.
				 */
				x = t*( t*endPt.x ) + (1-t)*( 2*t*ctrlPt.x + (1-t)*startPt.x );
				y = t*( t*endPt.y ) + (1-t)*( 2*t*ctrlPt.y + (1-t)*startPt.y );


				angle = Math.atan2( t*(endPt.y-ctrlPt.y) + (1-t)*(ctrlPt.y-startPt.y), t*(endPt.x-ctrlPt.x) + (1-t)*(ctrlPt.x-startPt.x) );

				// use a random detail image. the final parameter here is a pseudo-randomly chosen detail index.
				// if too slow, these land detail objects should be stored in a pool.
				this.drawQueue.push( new LandDetail( this.bottomClip, x, y, angle, this.bottomClip.totalFrames*this.randMap.getNumberAt(5*x,5*y)+1, -y ) );

			} // while-loop

		} //

		public function makeSideDetails( startPt:Point, ctrlPt:Point, endPt:Point ):void {
			
			if ( !this.sideClip ) {
				return;
			}
			
			var t:Number;

			var x:Number = ctrlPt.x;
			var y:Number = ctrlPt.y;

			var angle:Number;
			
			var count:int = Math.round(
				this.topDetail.minDetails + (this.topDetail.maxDetails - this.topDetail.minDetails) *
				( ( this.randMap.getIntAt( 3*y, 3*x )&0xFF) / 0x100 )
			);
			
			if ( count <= 0 ) {
				return;
			}
			var rate:Number = 1 / count;

			while ( --count >= 0 ) {
				
				t = rate*( count + this.randMap.getNumberAt( 10*x, 10*y ) );
				
				/**
				 * get the point at percent t according to the bezier curve equation.
				 */
				x = t*( t*endPt.x ) + (1-t)*( 2*t*ctrlPt.x + (1-t)*startPt.x );
				y = t*( t*endPt.y ) + (1-t)*( 2*t*ctrlPt.y + (1-t)*startPt.y );
				
				angle = Math.atan2( t*(endPt.y-ctrlPt.y) + (1-t)*(ctrlPt.y-startPt.y), t*(endPt.x-ctrlPt.x) + (1-t)*(ctrlPt.x-startPt.x) );

				this.drawQueue.push( new LandDetail( this.sideClip, x, y, angle, this.sideClip.totalFrames*this.randMap.getNumberAt(5*x,5*y)+1, -y ) );

			} // while-loop
			
		} //

		/**
		 * Draw all the details waiting in the queue.
		 */
		public function drawDetails( dest:BitmapData, offsetMatrix:Matrix, bounds:Rectangle ):void {

			var detail:LandDetail;

			if ( this.sortDetails ) {
				this.sortQueue();
			}

			// actually looping through the 'queue' in reverse order. since these are randomly chosen details, it doesn't actually matter.
			for( var i:int = this.drawQueue.length-1; i >= 0; i-- ) {

				detail = this.drawQueue[ i ];

				this.matrix.setTo( 1, 0, 0, 1, 0, 0 );

				this.matrix.rotate( detail.angle );
				this.matrix.tx = offsetMatrix.tx + detail.x;
				this.matrix.ty = offsetMatrix.ty + detail.y;

				detail.detail.gotoAndStop( detail.detailFrame );

				// draw the detail specified by the index.
				dest.draw( detail.detail, this.matrix, null, null, bounds );

			} // for-loop.

			// empty teh friggin queue.
			this.drawQueue.length = 0;

		} // drawDetails()

		/**
		 * sort the stupid friggin queue based on draw order. details lower on the screen
		 * cover details higher up or ground details look like theyre floating. leaves however,
		 * won't actually need this. maybe make an option to remove for leaves?
		 * 
		 * do a stupid insertion sort for now. can change
		 * to something else later.
		 */
		private function sortQueue():void {

			var len:int = this.drawQueue.length;

			var d:LandDetail;
			var temp:LandDetail;

			var j:int;
			var insert:int;

			for( var i:int = 1; i < len; i++ ) {

				d = this.drawQueue[i];

				j = i - 1;
				while ( j >= 0 ) {

					if ( this.drawQueue[j].drawOrder >= d.drawOrder ) {
						break;
					}

					this.drawQueue[j+1] = this.drawQueue[j];

					j--;

				} // while-loop.

				this.drawQueue[j+1] = d;

			} // for-loop.

		} //

		public function set renderContext( rc:RenderContext ):void {

			this.context = rc;

		} //

	} // class

} //