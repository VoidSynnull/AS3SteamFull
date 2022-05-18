package game.scenes.shrink.shared.particles
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class LazerParticle extends Emitter2D
	{
		public function LazerParticle()
		{
			super();
		}
		
		public function init( rate:int = 50, lifeTime:Number = .5, vel:Number = 250):void
		{
			this.counter = new Steady(rate);
			
			this.addInitializer(new ImageClass(Dot,[5], true));
			this.addInitializer(new Position(new PointZone(new Point(0, 0))));
			this.addInitializer(new Velocity(new DiscZone(new Point(),vel )));
			//like to figure out how to change color, but color and colors init dont work
			this.addInitializer(new ColorInit(0x00FF00, 0x99FF99));
			this.addInitializer(new AlphaInit());
			//they just make the particle disapear
			this.addInitializer(new ScaleImageInit(0.5, 1));
			this.addInitializer(new Lifetime(lifeTime));
			
			this.addAction(new Age());
			this.addAction(new Move());
			this.addAction( new RandomDrift( vel, vel ) );
		}
	}
}