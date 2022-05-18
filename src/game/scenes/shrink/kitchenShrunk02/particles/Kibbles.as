package game.scenes.shrink.kitchenShrunk02.particles
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ChooseInitializer;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.RotateVelocity;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class Kibbles extends Emitter2D
	{
		public function Kibbles()
		{
			super();
		}
		
		public function init(data:Array, particles:uint = 25):void
		{
			this.counter = new Steady(particles);
			var initialIzers:Array = [];
			
			for(var i:int = 0; i < data.length; i++)
			{
				initialIzers.push(new BitmapImage(data[i], true));
			}
			
			this.addInitializer( new ChooseInitializer(initialIzers));
			
			this.addInitializer( new Lifetime( 1, 2 ) );
			this.addInitializer( new Position( new DiscZone( new Point( 0, 0 ),25 ) ) );
			this.addInitializer( new Velocity( new PointZone(new Point(25,25))));
			this.addInitializer( new RotateVelocity(0, 45));
			
			this.addAction( new Age( ) );
			this.addAction( new Move( ) );
			this.addAction( new Accelerate( 0, 1000 ) );
			this.addAction( new RandomDrift( 300 ) );
		}
	}
}