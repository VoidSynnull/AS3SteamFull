/**
 * @author Scott Wszalek
 */
package game.particles.emitter
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import org.flintparticles.common.counters.Counter;
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
	
	public class Snow extends Emitter2D
	{
		public function init(counter:Counter, box:Rectangle):void
		{
			super.counter = counter;
			addInitializer(new ImageClass(Blob, [2, 0xFFFFFF], true));
			addInitializer(new Position(new RectangleZone(box.left, box.top, box.right, 1)));
			addInitializer(new Velocity(new LineZone(new Point(-100, 50), new Point(100, 200))));
			addInitializer(new ScaleImageInit(.75, 1.25));
			
			addAction(new Move());
			addAction(new RandomDrift(300, -25));
			addAction(new DeathZone(new RectangleZone(box.left - box.width, box.top - box.height, box.right * 2, box.bottom * 2), true));
		}
	}
}