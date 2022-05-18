package game.scenes.shrink.bedroomShrunk02.Particles
{
	import flash.geom.Point;
	
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ChooseInitializer;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class DustParticle extends Emitter2D
	{
		public function DustParticle()
		{
			super();
		}
		
		public function init( data:Array, rate:int = 10, vel:Number = 600 ):void
		{
			this.counter = new Steady( rate );
			
			var initialIzers:Array = [];
			
			for( var i:int = 0; i < data.length; i++ )
			{
				initialIzers.push( new BitmapImage( data[ i ], true ));
			}
			
			this.addInitializer( new ChooseInitializer( initialIzers ));
			this.addInitializer( new Position( new RectangleZone( 0, -10, 25, 10 )));
			this.addInitializer( new Velocity( new PointZone( new Point( vel, 0 ))));
			this.addInitializer( new ScaleImageInit( 0.25, .5 ));
			
			this.addAction( new DeathZone( new RectangleZone( 1115, -80, 1150, 50)));
			
			this.addAction( new Move());
			this.addAction( new RandomDrift( vel, vel/8 ));
		}
	}
}