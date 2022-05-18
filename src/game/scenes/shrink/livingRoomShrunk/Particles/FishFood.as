package game.scenes.shrink.livingRoomShrunk.Particles
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Pulse;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class FishFood extends Emitter2D
	{
		public function init( bitmapData:BitmapData, emitVelocity:Point, rate:Number = 12,lifetime:Number = 1, acceleration:Number = 1500):void
		{
			counter = new Pulse( 1, rate );
			
			addInitializer( new BitmapImage( bitmapData, true, 25 ));
			addInitializer( new Position( new RectangleZone(-25,-25,25,25) ) );
			addInitializer( new Velocity( new LineZone( new Point( emitVelocity.x / 2, emitVelocity.y / 2 ), emitVelocity)));
			addInitializer( new Lifetime( lifetime ) );
			
			addAction( new Age() );
			addAction( new Move() );
			addAction( new Accelerate(0, acceleration));
			addAction( new RandomDrift( Math.random() * emitVelocity.x * 2 - emitVelocity.x, Math.random() * emitVelocity.y));
		}
	}
}