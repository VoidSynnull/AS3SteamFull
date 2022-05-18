package game.scenes.time.shared.emitters
{
	import flash.geom.Point;
	
	import fl.motion.easing.Quadratic;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class SmokeBlast extends Emitter2D
	{
		public function SmokeBlast()
		{
		}
		
		public function init(box:RectangleZone, velocity:LineZone, count:Number = 3, size:Number = 8):void
		{
			super.counter = new Blast(count);
			
			addInitializer(new ImageClass(Blob, [size, 0xFFFFFF], true));
			addInitializer(new AlphaInit(.6));
			addInitializer(new ScaleImageInit(.7, 1));
			addInitializer(new Velocity(velocity));
			addInitializer(new Lifetime(1.8, 2.2));
			addInitializer(new Position(new LineZone(new Point(box.left, box.top), new Point(box.right, box.top))));
			
			addAction(new Move());
			addAction(new Age(Quadratic.easeOut));
			addAction(new Fade(.6, 0));
			addAction(new Accelerate(60, 70));
			addAction(new RandomDrift(200, 0));
		}
	}
}