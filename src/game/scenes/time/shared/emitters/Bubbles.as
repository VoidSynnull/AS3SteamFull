package game.scenes.time.shared.emitters
{
	import flash.geom.Point;
	
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Bubbles extends Emitter2D
	{
		public function Bubbles()
		{
		}
		
		public function init(box:RectangleZone):void
		{
			super.counter = new Random(3,4);
			addInitializer(new ImageClass(Dot, [3, 0xFFFFFF], true));
			addInitializer(new AlphaInit(.05, .3));
			addInitializer(new ScaleImageInit(.1, 1));
			addInitializer(new Position(new LineZone(new Point(box.left, box.bottom), new Point(box.right, box.bottom))));
			addInitializer(new Lifetime(4));
			
			addAction(new Move());
			addAction(new Accelerate(0, -100));
			addAction(new RandomDrift(0, -100));
			addAction(new DeathZone(box, true));
		}
	}
}