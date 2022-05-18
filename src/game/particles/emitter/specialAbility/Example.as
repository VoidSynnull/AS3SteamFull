package game.particles.emitter.specialAbility 
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Star;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	
	
	public class Example extends Emitter2D
	{
		public function Example() 
		{
			
		}
		
		public function init():void
		{
			super.counter = new Steady( 10 );
			addInitializer( new ImageClass( Star, [8], true ) );
			addInitializer( new ColorInit(0x990011, 0x4400FF) );	// initialize from a color range
			addInitializer( new AlphaInit( 1, 2) );				// initialize from a alpha range
			addInitializer( new Position( new RectangleZone( -25,-25,25,25)));
			addInitializer( new Velocity( new LineZone( new Point( -50, -120 ), new Point(50, -80))));
			addInitializer( new Lifetime( 1, 2 ) );
			
			addAction( new Age( Quadratic.easeIn ) );
			addAction( new Move() );
			addAction( new Accelerate( 0, 200 ) );
			addAction( new RandomDrift( 15, 15 ) );				// add a random drift
			addAction( new Fade() );								// cause alpha to decrease with age
			addAction( new ScaleImage( 1, .2) );					// cause scale to decrease with age
		}
		
		public function set rate(rate:int):void
		{
			Steady(super.counter).rate = rate;
		}
	}
}