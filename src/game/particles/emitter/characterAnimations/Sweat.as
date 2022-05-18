/**
 * ...
 * @author Bard
 */

 package game.particles.emitter.characterAnimations 
{
	import flash.geom.Point;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.zones.EllipseZone;

	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class Sweat extends Emitter2D
	{
		public function Sweat() 
		{
			
		}
		
		public function init():void
		{
			super.counter = new Random( 10, 20 );

		    addInitializer( new ImageClass( Dot, [3], true ) );
			addInitializer( new Position( new EllipseZone( new Point( -15, -15 ), 50, 5)));
		    addInitializer( new Velocity( new LineZone( new Point( -60, -80 ), new Point( 60, -140 ) ) ) );
			addInitializer( new Lifetime( 1.2, 1.5 ) );
		  
			addAction( new Age(Quadratic.easeIn) );
		    addAction( new RandomDrift( 10, 0 ) );
			addAction( new Accelerate(0,200) );
			addAction( new Fade( .5, 0 ) );
			addAction( new Move() );
		}
	}
}

