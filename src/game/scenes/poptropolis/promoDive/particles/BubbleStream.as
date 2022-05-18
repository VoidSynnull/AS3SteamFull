package game.scenes.poptropolis.promoDive.particles
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.TargetScale;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class BubbleStream extends Emitter2D
	{	
		public function BubbleStream() {
			
		}
		
		public function init():void
		{
			counter = new Random(.5, 3);
			
			addInitializer( new ImageClass( DiveBubble, [], true ) );
			addInitializer( new Velocity( new PointZone( new Point( 100, -20 ) ) ) );
			addInitializer( new ScaleImageInit( .0, .1) );
			addInitializer( new Lifetime( 2 ) );
			
			addAction( new Age() );
			addAction( new Move() );
			addAction( new RandomDrift( 200, 200 ) );
			addAction( new Accelerate(0, -50) );
			addAction( new TargetScale(1, 10) );
			addAction( new Fade(.3, 0) );
		}
	}
}