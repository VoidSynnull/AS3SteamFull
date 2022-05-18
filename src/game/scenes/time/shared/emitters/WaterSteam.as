package game.scenes.time.shared.emitters
{
	import flash.geom.Point;
	
	import fl.motion.easing.Quadratic;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.ScaleAll;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class WaterSteam extends Emitter2D
	{
		public function WaterSteam()
		{
		}
		
		public function init(box:RectangleZone, rate:Number = 4, size:Number = 8):void
		{
			super.counter = new Random(rate, rate*2);
			
			addInitializer(new ImageClass(Blob, [size, 0xFFFFFF], true));
			addInitializer(new AlphaInit(.6));
			addInitializer(new ScaleImageInit(.7, 1));
			addInitializer(new Lifetime(1.8, 2.2));
			addInitializer(new Position(new LineZone(new Point(box.left, box.bottom), new Point(box.right, box.bottom))));	
			
			addAction(new Move());
			addAction(new Age(Quadratic.easeOut));
			addAction(new ScaleAll(0.7,1.5));
			addAction(new Fade(.6, 0));
		}
	}
}