package game.scenes.shrink.shared.particles
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.initializers.ChooseInitializer;
	import org.flintparticles.common.initializers.ExternalImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.Rotate;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.RotateVelocity;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class BreakingGlass extends Emitter2D
	{
		public function BreakingGlass()
		{
			super();
		}
		public function init(glassHeight:Number, particles:Number = 50, direction:Number = -.758, vel:Number = 250, acc:Number = 500 ):void
		{
			this.counter = new Blast(particles);
			
			addInitializer( new ChooseInitializer([new ExternalImage("assets/scenes/shrink/shared/particles/shard.swf")]));
			this.addInitializer(new Position(new LineZone(new Point(0, glassHeight / 2), new Point(0, -glassHeight / 2))));
			this.addInitializer(new Velocity(new LineZone(new Point(Math.cos(direction) * vel, Math.sin(direction) * vel),new Point(Math.cos(direction) * -vel, Math.sin(direction) * vel))));
			this.addInitializer(new RotateVelocity(0, 45));
			this.addInitializer(new ScaleImageInit(0.5, 2));
			this.addInitializer( new Lifetime( 1, 2 ) );;
			
			this.addAction(new Age());
			this.addAction(new Move());
			this.addAction( new Accelerate(0, acc));
			this.addAction(new Rotate());
			this.addAction( new RandomDrift( vel, vel ) );
		}
	}
}