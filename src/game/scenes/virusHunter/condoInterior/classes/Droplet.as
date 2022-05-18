package game.scenes.virusHunter.condoInterior.classes {
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	
	public class Droplet extends Sprite {

		static public var DROPLET:int = 1;
		static public var RIPPLE:int = 2;

		static public var DEG_PER_RAD:Number = 180 / Math.PI;

		public var vx:Number;
		public var vy:Number;

		public var mode:int = DROPLET;

		public var bitmap:Bitmap;
		public var ripple:Ripple;

		public function Droplet( bitmapData:BitmapData ) {

			super();

			bitmap = new Bitmap( bitmapData );
			bitmap.x = -bitmap.width;
			bitmap.y = -bitmap.height;

			this.addChild( bitmap );

		} // end Droplet()

		public function update():Boolean {

			if ( mode == DROPLET ) {

				this.vy += 1.5;
				this.x += this.vx*this.scaleX;
				this.y += this.vy*this.scaleX;

				this.rotation = Math.atan2( this.vy, this.vx ) * DEG_PER_RAD;

			} else {

				if ( ripple.update() == true ) {
					return true;				// droplet is done.
				} //

			} // end-if.

			return false;

		} // end update()

		public function makeRipple():void {

			this.removeChild( bitmap );

			this.rotation = 0;

			mode = RIPPLE;

			ripple = new Ripple();
			this.addChild( ripple );

		} //

	} // End Droplet
	
} // End package 