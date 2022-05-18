package game.particles.emitter
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class WaterStream extends Emitter2D
	{
		public function init(bounds:Rectangle, count:Number = 20, size:Number = 20, color:uint = 0x00FFFF, alpha:Number = .3, velocity:Number = 200):void
		{
			var diff:int = bounds.right - bounds.left;
			
			this.counter = new Steady(count);
			addInitializer(new ImageClass(Blob, [size, color], true));
			addInitializer(new AlphaInit(alpha));
			addInitializer(new Position(new RectangleZone(bounds.left + diff*.3, bounds.top, bounds.right - diff*.3, bounds.top)));
			addInitializer(new Velocity(new LineZone(new Point(0, velocity), new Point(0, velocity))));
		
			addAction(new DeathZone(new RectangleZone(bounds.left, bounds.top, bounds.right, bounds.bottom), true));
			addAction(new RandomDrift(200));
			addAction(new Move());
		}
	}
}