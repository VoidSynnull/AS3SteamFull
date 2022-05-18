package game.scenes.shrink.livingRoomShrunk.Particles
{
	import flash.geom.Rectangle;
	
	import game.util.BitmapUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class StaticElectricity extends Emitter2D
	{
		public function StaticElectricity(emitLocation:Rectangle,length:Number = 100, zigs:uint = 10, rate:Number = 25, lifetime:Number = 1, drift:Number = 1)
		{
			counter = new Steady(rate);
			
			addInitializer( new BitmapImage(BitmapUtils.createBitmapData(new StaticSpark(length,zigs)), true ) );
			addInitializer( new Position( new RectangleZone(emitLocation.left,emitLocation.top,emitLocation.right,emitLocation.bottom ) ) );
			addInitializer( new ScaleImageInit(.5,2) );
			addInitializer( new Lifetime( lifetime) );
			
			addAction(new Fade(1,0));
			addAction( new Age() );
			addAction( new Move() );
			addAction( new RandomDrift( drift * Math.random(), drift * Math.random()));
		}
	}
}