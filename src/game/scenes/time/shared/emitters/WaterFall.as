package game.scenes.time.shared.emitters
{
	import flash.geom.Point;
	
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Ellipse;
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
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class WaterFall extends Emitter2D
	{
		public function WaterFall()
		{
		}
		
		public function init(box:RectangleZone):void
		{
			super.counter = new Random(20,30);
			addInitializer(new ImageClass(Ellipse, [9, 25, 0xFFFFFF], true));
			addInitializer(new AlphaInit(.05, .3));
			addInitializer(new Velocity(new PointZone(new Point(0,300))));
			addInitializer(new ScaleImageInit(.3, 1));
			addInitializer(new Position(new LineZone(new Point(box.right, box.top), new Point(box.left, box.top))));
			addInitializer(new Lifetime(4));
			
			addAction(new Move());
			addAction(new Accelerate(0, 400));
			addAction(new RandomDrift(0, 100));
			addAction(new DeathZone(box, true));
		}
	}
}