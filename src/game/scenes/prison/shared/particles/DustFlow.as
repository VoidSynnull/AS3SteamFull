package game.scenes.prison.shared.particles
{	
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.Zone2D;
	
	public class DustFlow extends Emitter2D
	{
		
		private var activeVelocity:Velocity;
		
		public function DustFlow()
		{
			super();
		}
		
		public function init(direction:Number, speed:Number = 100, size:Number = 8, rate:Number = 1, color:uint = 0xffffff, killZone:Zone2D = null):void
		{
			super.counter = new Random(rate,rate*2);
			
			addInitializer( new ImageClass( Blob, [size, color], true ) );
			addInitializer( new AlphaInit( 0.4, 0.5 ));
			addInitializer( new Lifetime( 1.5, 2.5 ) );
			
			var velocity:Point = new Point();
			velocity.x = Math.cos(direction) * speed;
			velocity.y = Math.sin(direction) * speed;
			activeVelocity =  new Velocity( new PointZone(velocity));
			addInitializer(activeVelocity);
			addInitializer( new Position( new EllipseZone(new Point(0,0),20,20)));
			if(killZone){
				addAction( new DeathZone(killZone,true));
			}
			addAction( new Age( Quadratic.easeOut ) );
			addAction( new Move() );
			addAction( new RandomDrift( 10, 10 ) );
			addAction( new ScaleImage( 0.6, 1.4 ) );
			addAction( new Fade(0.5, 0));
		}
		
		public function changeDirection(direction:Number, speed:Number = 100):void
		{
			removeInitializer(activeVelocity);
			var velocity:Point = new Point();
			velocity.x = Math.cos(direction) * speed;
			velocity.y = Math.sin(direction) * speed;
			activeVelocity = new Velocity( new PointZone(velocity))
			addInitializer( activeVelocity);
		}
		
	}
}