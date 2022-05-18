package game.scenes.examples.particlesExample.particles
{
	import flash.geom.Point;
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.PointZone;
	/**
	 * ...
	 * @author Bard McKinley
	 */
	public class ParticleExample1 extends Emitter2D
	{
		public function init():void
		{
			super.counter = new Steady(4);
	
			super.addInitializer( new ImageClass( Dot, [2], true ) );
			super.addInitializer( new Position( new PointZone() ));
			super.addInitializer( new Velocity( new PointZone( new Point( -50, -100 ) ) ) );
			super.addInitializer( new Lifetime( 1.5 ) );

			super.addAction( new Age() );
			super.addAction( new Move() );
			super.addAction( new Accelerate(0, 200) );
		}
	}

}