package game.particles.emitter.specialAbility
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.common.actions.Age;

	public class FireworkTrails extends Emitter2D
	{
		public function init():void
		{
			var startVelocity : Point = new Point( 0, 330 );
			
			super.counter = new Steady(9);
			addInitializer( new Lifetime(2, 2) );
			addInitializer( new ImageClass( Dot, [12, 0xCD4D2B], true ) );
			addInitializer( new ScaleImageInit( 1.2, .5) );
			
			addAction( new Age() );
			addAction( new Move() );
			addAction( new LinearDrag(.2) );
			addAction( new RotateToDirection() );
			addAction( new Accelerate(0, 500) );
			addAction( new Fade(1, 0));
			//runAhead( 120 );
		}
	}
}