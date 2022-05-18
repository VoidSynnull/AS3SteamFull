package game.scenes.shrink.schoolInterior
{
	import flash.geom.Point;
	
	import game.util.BitmapUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Droplet;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Rotation;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class SprayEmitter extends Emitter2D
	{
		private var _oneShot:Boolean;
		public function SprayEmitter(oneShot:Boolean = false)
		{
			_oneShot = oneShot;
			super();
		}
		
		public function init( rate:int = 20, lifeTime:Number = .5, direction:Number = -.758, vel:Number = 500, acc:Number = 1000, color1:uint = 0xC8D7E1, color2:uint = 0xB0C3CC, deathZone:DeathZone = null ):void
		{
			if(_oneShot)
				this.counter = new Blast( rate );
			else
				this.counter = new Steady( rate );
			
			this.addInitializer(new BitmapImage(BitmapUtils.createBitmapData( new Droplet( 1.5 )), true ));
			this.addInitializer(new Position( new PointZone( new Point(0, 0))));
			this.addInitializer(new Velocity( new PointZone( new Point(Math.cos(direction) * vel, Math.sin(direction) * vel))));
			
			this.addInitializer(new Rotation(direction));
			this.addInitializer(new ColorInit(color1, color2));
			this.addInitializer(new AlphaInit());
			this.addInitializer(new ScaleImageInit(1, 2));
			this.addInitializer(new Lifetime(lifeTime));
			
			if( deathZone )
			{
				this.addAction( deathZone );
			}
			this.addAction(new Age());
			this.addAction(new Move());
			this.addAction( new Accelerate(0, acc));
			this.addAction( new RotateToDirection() );
			this.addAction( new RandomDrift( 2 * vel * Math.sin(direction), 2 * vel * Math.cos(direction) ) );	
		}
	}
}