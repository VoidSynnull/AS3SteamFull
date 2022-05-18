package game.scenes.survival1.shared.particles
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.PolyStar;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.Rotate;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.RotateVelocity;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	/**
	 * Author: Drew Martin
	 */
	public class FlintSparks extends Emitter2D
	{
		/**
		 * Creates flint and striker sparks when the two collide in the FirePopup.
		 */
		public function FlintSparks()
		{
			this.counter = new Blast(10);
			
			this.addInitializer(new ImageClass(PolyStar, [10, 4, 4], true));
			this.addInitializer(new Position(new PointZone(new Point())));
			this.addInitializer(new Velocity(new RectangleZone(-100, -100, 100, 100)));
			this.addInitializer(new ScaleImageInit(0.5, 1));
			this.addInitializer(new RotateVelocity(-2, 2));
			this.addInitializer(new Lifetime(0.5));
			
			this.addAction(new Fade());
			this.addAction(new Age());
			this.addAction(new Move());
			this.addAction(new Rotate());
			this.addAction(new RandomDrift(200, 200));
			this.addAction(new Accelerate(0, 300));
		}
	}
}