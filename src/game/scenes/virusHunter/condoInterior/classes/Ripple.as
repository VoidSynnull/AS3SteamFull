package game.scenes.virusHunter.condoInterior.classes {
	
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;

	// Currently all the time units are measured in frames. Since a ripple effect
	// is hardly a time-critical process, this should be fine.
	public class Ripple extends Sprite {

		// time between creation of ripple rings.
		public var rate:int = 18;

		public var startWidth:Number = 2.9;
		public var startHeight:Number = 1.2;

		public var maxWidth:Number = 42.8;
		public var maxHeight:Number = 5.2;

		public var growTime:int = 30;

		public var color:uint = 0xC8D7E1

		// ripple rings.
		public var rings:Vector.<Shape>;

		public var time:int;
		public var maxAge:int = 30;

		public var maxRings:int = 2;

		public function Ripple() {

			super();

			time = 0;

			rings = new Vector.<Shape>();

			makeRing();

		} //

		// Returns true when the ripple has passed its age.
		public function update():Boolean {

			if ( time++ == maxAge ) {
				return true;
			}

			var s:Shape;
			var wspeed:Number = (maxWidth - startWidth)/growTime;
			var hspeed:Number = (maxHeight - startHeight)/growTime;

			for( var i:int = rings.length-1; i >= 0; i-- ) {

				s = rings[i];
				s.width += wspeed;
				s.height += hspeed;

				if ( s.width >= maxWidth ) {

					this.removeChild( s );
					rings[i] = rings[rings.length-1];
					rings.pop();

				} //

			} // end for-loop.

			// check ring creation.
			if ( maxRings > 0 && (time % rate) == 0 ) {
				makeRing();
			} //

			return false;

		} //

		private function makeRing():void {

			var s:Shape = new Shape();
			var g:Graphics = s.graphics;

			g.lineStyle( 1, color );
			g.drawCircle( 0, 0, 10 );

			s.width = startWidth;
			s.height = startHeight;

			this.addChild( s );

			rings.push( s );

			maxRings--;

		} //

	} // End Ripple
	
} // End package