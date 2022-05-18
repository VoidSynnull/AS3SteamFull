package game.scenes.carnival.shared.game3d.geom {

	public class Shape3D {

		/**
		 * Constants give the possible results of a hit test between two shape objects.
		 * A result of undefined indicates the given shape does not recognize or have
		 * a test function for the given object.
		 */
		static public const HIT:int = 1;
		static public const NO_HIT:int = 0;
		static public const UNDEFINED:int = -1;

		/**
		 * Extremely unfortunate that we have to replicate these from Spatial3D. Could link Spatial3D
		 * here but then you'd need the Spatial3D even if you weren't using the shape in an entity...
		 */
		public var x:Number;
		public var y:Number;
		public var z:Number;

		public function Shape3D( tx:Number=0, ty:Number=0, tz:Number=0 ) {

			this.x = tx;
			this.y = ty;
			this.z = tz;

		}

		/**
		 * By default, no hit functions are defined.
		 */
		public function testHit( s:Shape3D ):int {

			return Shape3D.UNDEFINED;

		} //

	} // End Shape3D
	
} // End package