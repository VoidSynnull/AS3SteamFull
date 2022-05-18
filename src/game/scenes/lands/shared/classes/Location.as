package game.scenes.lands.shared.classes {

	/**
	 * like a point but with integers instead of numbers.
	 * tracks scene locations within a world.
	 */

	public class Location {

		public var x:int;
		public var y:int;

		/*static public function XCoord( n:int ):int {
			return n & 0xFFFF;
		} //

		static public function YCoord( n:int ):int {
			return ( n >> 16 );
		}

		static public function Encode( x:int, y:int ):int {
			return ( x + (y << 16 ) );
		}*/

		public function Location( lx:int=0, ly:int=0 ) {

			this.x = lx;
			this.y = ly;

		} //

		public function setTo( nx:int, ny:int ):void {

			this.x = nx;
			this.y = ny;

		} //

		public function fromString( s:String, radix:int=16):void {

			var a:Array = s.split( "," );
			this.x = parseInt( a[0], radix );
			this.y = parseInt( a[1], radix );

		} //

		/**
		 * the inverse operation of combine, pulls y,x apart from the bytes of an int.
		 */
		/**public function separate( n:uint ):void {

			x = n & 0xFFFF;
			y = n >> 16;

		} //*/

		/**
		 * combines the location coordinates into a single number.
		 * assumes x,y coords are both 2 bytes in size and positive.
		 */
		/*public function combine():int {

			return x + ( y << 16 );

		} //*/

		public function toString():String {

			return this.x.toString( 16 ) + "," + this.y.toString( 16 );

		} //

	} // class
	
} // package