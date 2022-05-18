package game.scenes.timmy.skyScraper
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.RadialDot;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.zones.DiscZone;

	
	public class PieSplash extends Emitter2D
	{		
		public function init():void
		{
			
			counter = new Blast(10);
			
			addInitializer( new ImageClass( RadialDot, [1], true, 10 ) );
			//addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 200, 50, 90, 45 ) ) );
			addInitializer( new Velocity( new DiscZone( new Point( 0, 0 ), 150, 100 ) ) );
			addAction( new ScaleImage( 4, 5 ) );
			addInitializer( new ColorInit(0xFF0000, 0xFF0000) );
			addInitializer( new Lifetime(.2,1 ) );
			
			addAction( new Age() );
			addAction( new Move() );
			addAction( new Accelerate(0, 300) );
			addAction( new Fade( 1, 0.5 ) );
			//addAction( new RandomDrift( 600, 300 ) );
		}
	}
}