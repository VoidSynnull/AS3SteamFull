package game.scenes.carnival.shared.game3d.geom {

	public class Box3D extends Shape3D {

		public var halfHeight:Number;
		public var halfWidth:Number;
		public var halfDepth:Number;

		public function Box3D( width:Number, height:Number, depth:Number ) {

			super();

			this.halfHeight = height/2;
			this.halfWidth = width/2;
			this.halfDepth = depth/2;

		}

		override public function testHit( s:Shape3D ):int {

			if ( s is Box3D ) {
				return this.testBox( s as Box3D );
			}

			return Shape3D.UNDEFINED;

		} //

		public function testBox( b:Box3D ):int {

			if ( Math.abs(b.x - this.x) > (b.halfWidth + this.halfWidth) ||
				Math.abs(b.y - this.y) > (b.halfHeight + this.halfHeight) ||
				Math.abs(b.z - this.z) > (b.halfDepth + this.halfDepth) ) {

				return Shape3D.NO_HIT;
			}

			return Shape3D.HIT;

		} //

	} // End Box3D

} // End package