package game.scenes.lands.shared.tileLib.generation.data {

	import flash.geom.Point;

	public class TreeLine {

		public var startPt:Point;
		public var endPt:Point;

		/**
		 * these numbers are used in several places. no need to recompute.
		 */
		public var dx:Number;
		public var dy:Number;

		public var halfThickness:Number;

		/**
		 * used for tapered lines. this is actually a half-thickness value.
		 */
		public var endThickness:Number;

		public var length:Number;

		public function TreeLine() {

		} // TreeLine

		public function setEndPoints( p0:Point, p1:Point, halfThickness:Number ):void {

			this.startPt = p0;
			this.endPt = p1;

			this.halfThickness = halfThickness;
			this.endThickness = halfThickness;

			this.dx = p1.x - p0.x;
			this.dy = p1.y - p0.y;

			this.length = Math.sqrt( this.dx*this.dx + this.dy*this.dy );

			this.dx /= this.length;
			this.dy /= this.length;

		} //

		/**
		 * the branch dx,dy and length need to be recomputed when either of the end points are changed
		 * in order for the branch to work with the scanLineFill algorithm.
		 */
		public function recompute():void {

			this.dx = this.endPt.x - this.startPt.x;
			this.dy = this.endPt.y - this.startPt.y;
			
			this.length = Math.sqrt( this.dx*this.dx + this.dy*this.dy );
			
			this.dx /= this.length;
			this.dy /= this.length;

		} //

	} // class

} // package