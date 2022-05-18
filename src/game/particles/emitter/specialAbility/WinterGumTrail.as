package game.particles.emitter.specialAbility
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.initializers.ChooseInitializer;
	import org.flintparticles.common.initializers.ExternalImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.PointZone;
	
	
	
	public class WinterGumTrail extends Emitter2D
	{
		
		public function init():void
		{
			var startVelocity : Point = new Point( 0, 50 );
			
			super.counter = new Steady(4);
			
			addInitializer( new ChooseInitializer([new ExternalImage("assets/particles/flake1.swf"), 
				new ExternalImage("assets/particles/flake2.swf"),
				new ExternalImage("assets/particles/flake3.swf")]));
			addInitializer( new Velocity( new PointZone( startVelocity ) ) );
			addInitializer( new ScaleImageInit( .25, 1) );
			addInitializer(new Lifetime(2, 4));
			
			addAction(new Age());
			addAction( new Move() );
			addAction( new RandomDrift( 400, 0 ) );
			addAction( new RotateToDirection() );
			addAction( new Accelerate(0, 50) );
		}
	}
}