package game.particles.emitter
{
	import flash.geom.Point;
	
	import org.flintparticles.common.counters.Counter;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ColorsInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	/**
	 * Author: Drew Martin
	 * 
	 * <p>The <code>Storm</code> emitter deals with all natural forms of falling weather particles.
	 * Given the right particle, color, and motion, a <code>Storm</code> could handle:</p>
	 * <li>Droplet: Rainstorms, Hailstorms</li>
	 * <li>Blob: Snowstorms, Meteor Showers</li>
	 * <li>Much more!</li>
	 */
	public class Storm extends Emitter2D
	{
		/**
		 * @param Counter: Counter-extending class.
		 * @param Particle: Particle class.
		 * @param Parameters: Particle parameters.
		 * @param Box: RectangleZone box.
		 * @param Velocity: Particle velocity.
		 * @param Acceleration: Optional acceleration.
		 * @param Drift: Optional random drift.
		 * @param Colors: Optional colors. Defaults to 4 blues.
		 * @param Alpha: Optional alpha. Defaults to 1.
		 * @param UseBox: True: Spawns in the box. False: Spawns at the top of the box.
		 */
		public function init(counter:Counter, particle:Class, parameters:Array, box:RectangleZone, velocity:RectangleZone, acceleration:Point = null, drift:Point = null, colors:Array = null, alpha:Number = 1, useBox:Boolean = false):void
		{
			//Counter
			this.counter = counter;
			
			//Initializers
			addInitializer(new ImageClass(particle, parameters, true));
			addInitializer(new ScaleImageInit(0.5, 1.5));
			addInitializer(new AlphaInit(alpha));
			addInitializer(new Velocity(velocity));
			
			if(useBox) addInitializer(new Position(box));
			else addInitializer(new Position(new LineZone(new Point(box.left, box.top), new Point(box.right, box.top))));
			
			if(!colors) colors = [0xFF96E1FF, 0xFF00D2FF, 0xFF96AFFF, 0xFF0041FF];
			addInitializer(new ColorsInit(colors));
			
			//Actions
			addAction(new Move());
			addAction(new RotateToDirection());
			addAction(new DeathZone(box, true));
			if(drift) addAction(new RandomDrift(drift.x, drift.y));
			if(acceleration) addAction(new Accelerate(acceleration.x, acceleration.y));
		}
	}
}