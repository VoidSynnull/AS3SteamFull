package game.scenes.poptropolis.weightLift.particles
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.TargetScale;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	
	public class StarBlast extends Emitter2D
	{
		public function init():void
		{
			super.counter = new Blast(30);
	
			super.addInitializer( new ImageClass( Star, [], true ) );
			super.addInitializer( new Velocity( new DiscZone( new Point( 0, 0 ), 300, 50 ) ) );
			super.addInitializer( new Lifetime( 2 ) );

			super.addAction( new Age() );
			super.addAction( new Move() );
			super.addAction( new Fade() );
			super.addAction( new TargetScale(10) );
		}
	}
}