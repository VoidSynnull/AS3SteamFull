package game.scenes.shrink.kitchenShrunk01.Particles
{
	import flash.geom.Point;
	
	import game.util.BitmapUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class Fog extends Emitter2D
	{
		public function Fog()
		{
			super();
		}
		
		public function init( rate:int = 10, size:Number = 25, range:Number = 100, lifeTime:Number = .5, direction:Number = -.758, spread:Number = .758, vel:Number = 50, acc:Number = -100, deathZone:DeathZone = null ):void
		{
			this.counter = new Steady(rate);
			
			this.addInitializer(new BitmapImage(BitmapUtils.createBitmapData(new Blob(size)), true));
			this.addInitializer(new Position(new LineZone(new Point(-Math.sin(direction) * range / 2, -Math.cos(direction) * range / 2), new Point(Math.sin(direction) * range / 2, Math.cos(direction) * range / 2))));
			this.addInitializer(new Velocity(new LineZone(new Point(Math.cos(direction + spread / 2) * vel, Math.sin(direction + spread / 2) * vel), new Point(Math.cos(direction - spread / 2) * vel, Math.sin(direction - spread / 2) * vel))));
			//like to figure out how to change color, but color and colors init dont work
			this.addInitializer(new ColorInit());
			this.addInitializer(new AlphaInit(0,.5));
			//they just make the particle disapear
			this.addInitializer(new ScaleImageInit(0.5, 1));
			this.addInitializer(new Lifetime(lifeTime));
			
			if( deathZone )
			{
				this.addAction( deathZone );
			}
			this.addAction(new Age());
			this.addAction(new Move());
			this.addAction( new Accelerate(0, acc));
			this.addAction( new RandomDrift( vel, vel ) );	
			this.addAction(new Fade(.5))
		}
	}
}