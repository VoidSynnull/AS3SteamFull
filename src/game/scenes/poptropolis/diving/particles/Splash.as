package game.scenes.poptropolis.diving.particles
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

	
	public class Splash extends Emitter2D
	{		
		public function init():void
		{
			
			counter = new Blast(500);
			
			addInitializer( new ImageClass( RadialDot, [1], true ) );
			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 200, 50, 90, 45 ) ) );
			//addInitializer( new Velocity( new DiscZone( new Point( 0, 0 ), 350, 200 ) ) );
			addAction( new ScaleImage( .5, 6 ) );
			addInitializer( new ColorInit(0xFF21AAF8, 0xFF21AAF8) );
			addInitializer( new Lifetime(.2,1 ) );
			
			addAction( new Age() );
			addAction( new Move() );
			addAction( new Accelerate(100, 200) );
			addAction( new Fade( 1, 0 ) );
			addAction( new RandomDrift( 600, 300 ) );
		}
	}
}