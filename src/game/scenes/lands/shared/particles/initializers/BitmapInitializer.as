package game.scenes.lands.shared.particles.initializers {

	/**
	 * initializes particle colors in an emitter with colors randomly chosen from a bitmap.
	 */
	import flash.display.BitmapData;
	
	import org.flintparticles.common.emitters.Emitter;
	import org.flintparticles.common.initializers.InitializerBase;
	import org.flintparticles.common.particles.Particle;
	
	public class BitmapInitializer extends InitializerBase {

		private var colorBitmap:BitmapData;

		public function BitmapInitializer( bm:BitmapData ) {

			super();

			this.colorBitmap = bm;

		} // BitmapInitializer

		public function get bitmap():BitmapData {
			return this.colorBitmap;
		}

		public function set bitmap( bm:BitmapData ):void {
			this.colorBitmap = bm;
		}

		/**
		 * @inheritDoc
		 */
		override public function initialize( emitter:Emitter, particle:Particle ):void {

			if ( this.colorBitmap != null ) {
				particle.color = this.colorBitmap.getPixel32( Math.random()*this.colorBitmap.width, Math.random()*this.colorBitmap.height );
			} else {
				particle.color = 0;
			}

		} //

	} // class

} // package