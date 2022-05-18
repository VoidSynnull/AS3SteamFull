package game.scenes.time.shared.emitters
{
	import fl.motion.easing.Quadratic;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ColorChange;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.Zone2D;
	
	/**
	 * @author Scott Wszalek
	 */
	public class FireSmoke extends Emitter2D
	{
		public function FireSmoke()
		{
			
		}
		
		public function init(size:Number, velocity:Zone2D, position:Zone2D):void
		{
			super.counter = new Random(6,7);
			
			addInitializer(new ImageClass(Blob, [size, 0xEEEEEE], true));
			addInitializer(new AlphaInit(.3, .5));
			addInitializer(new ScaleImageInit(.7, 1));
			addInitializer(new Velocity(velocity));
			addInitializer(new Lifetime(.6, .8));
			addInitializer(new Position(position));
			
			addAction(new Move());
			addAction(new Age(Quadratic.easeOut));
			addAction(new Fade(.5, 0));
			addAction(new ColorChange(0xFFCC00, 0xEEEEEE));
			addAction(new Accelerate(0, -100));
		}
	}
}