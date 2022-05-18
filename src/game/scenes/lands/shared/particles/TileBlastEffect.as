package game.scenes.lands.shared.particles {

	import flash.display.BitmapData;
	import flash.geom.Point;
	
	import game.scenes.lands.shared.particles.initializers.BitmapInitializer;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;

	public class TileBlastEffect extends Emitter2D {

		private var bitmapInit:BitmapInitializer;
		private var ellipse:EllipseZone;

		private var scaling:ScaleImageInit;

		public function init():void {

			this.counter = new Blast( 6 );

			// the [1] is the parameter to the Dot constructor, in this case, radius.
			super.addInitializer( new ImageClass( Blob, [4], true ) );

			this.ellipse = new EllipseZone( new Point( 0, 0 ), 20, 20 );
			super.addInitializer( new Position( this.ellipse ) );

			super.addInitializer( new Velocity( new EllipseZone( new Point( 0, -100 ), 200, 200 ) ) );

			this.scaling = new ScaleImageInit( 0.5, 2 );
			super.addInitializer( this.scaling );

			// better set this before it goes away.
			this.bitmapInit = new BitmapInitializer( null );
			super.addInitializer( this.bitmapInit );

			super.addInitializer( new Lifetime( 2 ) );

			super.addAction( new Age() );
			super.addAction( new Move() );
			super.addAction( new Accelerate(0, 800) );

		} // init()

		/**
		 * p is the probability that a blast will happen at all,
		 * blastCount is how many particles will spawn if there is one.
		 */
		public function randomBlast( p:Number, blastCount:int ):void {

			if ( Math.random() > p ) {

				( this.counter as Blast ).startCount = 0;

			} else {

				( this.counter as Blast ).startCount = blastCount;

			} //

		} //

		public function setCount( count:int ):void {

			( this.counter as Blast ).startCount = count;

		} //

		public function setParticleScale( min:Number, max:Number ):void {

			this.scaling.minScale = min;
			this.scaling.maxScale = max;

		} //

		public function setBlastCenter( x:Number, y:Number ):void {

			this.ellipse.centerX = x;
			this.ellipse.centerY = y;

		} //

		/*public function set blastRadius( r:Number ):void {

			this.ellipse.xRadius = r;
			this.ellipse.yRadius = r;

		} //*/

		public function set bitmap( bm:BitmapData ):void {

			this.bitmapInit.bitmap = bm;

		} //

	} // class

} // package

