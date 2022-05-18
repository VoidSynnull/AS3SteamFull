package game.scenes.time.shared.emitters
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	/**
	 * 
	 * @author Scott Wszalek
	 */
	public class Debris extends Emitter2D
	{
		public function init(box:Rectangle):void
		{
			super.counter = new Random(1, 2);
			addInitializer(new ImageClass(Blob, [1.3, 0x000000], true));
			addInitializer(new Position(new RectangleZone(box.left, box.top, 1, box.bottom)));
			addInitializer(new Velocity(new LineZone(new Point(100, -50), new Point(200, 50))));
			addInitializer(new ScaleImageInit(1, 1.5));
			
			addAction(new Move());
			addAction(new RandomDrift(0, 50));
			addAction(new DeathZone(new RectangleZone(box.left, box.top, box.right, box.bottom), true));
		}
	}
}