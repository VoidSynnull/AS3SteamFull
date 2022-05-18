package game.scenes.survival1.shared.particles
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ColorMultiChange;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.data.ColorStep;
	import org.flintparticles.common.displayObjects.RadialDot;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.AccelerateToPoint;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	
	/**
	 * Author: Drew Martin
	 */
	public class CampFire extends Emitter2D
	{
		/**
		 * Creates a campfire-like emitter. All particles gradually transition to a gray smoke color while
		 * reaching the end of their lifetime. Particles are drawn towards each other into a cone shape.
		 * 
		 * @param Radius: The radius of the base of the campfire.
		 * @param Rate: The number of particles the Steady counter should produce a second.
		 * @param AccelerationX: An acceleration that visually indicates what direction the wind is blowing.
		 */
		public function CampFire(radius:Number, rate:Number = 4, accelerationX:Number = 0)
		{
			this.start();
			
			this.counter = new Steady(rate);
			
			this.addInitializer(new ImageClass(RadialDot, [30], true));
			this.addInitializer(new Position(new LineZone(new Point(-radius, 0), new Point(radius, 0))));
			this.addInitializer(new Velocity(new LineZone(new Point(0, 0), new Point(0, -50))));
			this.addInitializer(new ScaleImageInit(0.75, 1));
			this.addInitializer(new Lifetime(2.5));
			
			this.addAction(new Age());
			this.addAction(new Move());
			//this.addAction(new GravityWell(300, 20, -225));
			this.addAction(new AccelerateToPoint(800, 20, 0, "x"));
			this.addAction(new RandomDrift(50, 0));
			this.addAction(new ColorMultiChange(new ColorStep(0x00FFEFAE, 1), new ColorStep(0xAAFFCC00, 0.9), new ColorStep(0x99F2410D, 0.7), new ColorStep(0x00CCCCCC, 0.2)));
			this.addAction(new Accelerate(accelerationX, -150));
		}
	}
}