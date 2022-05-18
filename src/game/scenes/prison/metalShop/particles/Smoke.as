package game.scenes.prison.metalShop.particles
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class Smoke extends Emitter2D
	{
		public function Smoke()
		{
			super();
		}
		
		public function init(size:Number = 16, rate:Number = 20, color:uint = 0xffffff):void
		{
			super.counter = new Steady( rate );
			
			addInitializer( new ImageClass( Blob, [size, color], true ) );
			addInitializer( new AlphaInit( .6, .7 ));
			addInitializer( new Lifetime( 0.7, 1.4 ) ); 
			addInitializer( new Velocity( new LineZone( new Point( -25, -100), new Point( -35, -150 ) ) ) );
			addInitializer( new Position( new LineZone(new Point(-20,0),new Point(20,0))));
			
			addAction( new Age( Quadratic.easeOut ) );
			addAction( new Move() );
			addAction( new RandomDrift( 130, 130 ) );
			addAction( new ScaleImage( .6, 1.6 ) );
			addAction( new Fade(.7, 0));
			//addAction( new Accelerate( 20, -60) );
		}
	}
}