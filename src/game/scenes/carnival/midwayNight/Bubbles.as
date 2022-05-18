package game.scenes.carnival.midwayNight
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Ring;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Bubbles extends Emitter2D
	{
		public function init(emitLocation:Rectangle, emitVelocity:Point, scaleRange:Point,rate:Number = 10,lifetime:Number = .5, bubbleSize:Number = 1, outlineWidth:Number = .1, acceleration:Number = -50):void
		{
			counter = new Steady(rate);
			
			addInitializer( new ImageClass( Ring, [bubbleSize, bubbleSize + outlineWidth], true ) );
			addInitializer( new Position( new RectangleZone(emitLocation.left,emitLocation.top,emitLocation.right,emitLocation.bottom ) ) );
			addInitializer( new Velocity( new PointZone(emitVelocity) ) );
			addInitializer( new ScaleImageInit(scaleRange.x, scaleRange.y) );
			addInitializer( new ColorInit(0x66FFFFFF, 0x66FFFFFF) );
			addInitializer( new Lifetime( lifetime ) );
			
			addAction( new Age() );
			addAction( new Move() );
			addAction( new Accelerate(0, acceleration));
			addAction( new RandomDrift( Math.random() * emitVelocity.x * 2 - emitVelocity.x, Math.random() * emitVelocity.y));
		}
	}
}