package game.particles.emitter.specialAbility
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ChooseInitializer;
	import org.flintparticles.common.initializers.ColorsInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.AntiGravity;
	import org.flintparticles.twoD.actions.CircularAcceleration;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	
	public class ConfettiBomb extends Emitter2D
	{
		public function ConfettiBomb()
		{
		}
		
		/**
		 * Init emitter (accept two color values)
		 * @param color1
		 * @param color2
		 * @param counterNum
		 */
		public function init(color1:uint = 0xFFFBAF, color2:uint = 0xCFB776, counterNum:uint = 30):void
		{
				super.counter = new Blast(counterNum);
				
				this.addInitializer(new ChooseInitializer([new ImageClass(Blob, [3, color1], true), new ImageClass(Blob, [5, color2], true)]));
				this.addInitializer(new ScaleImageInit(.5, 1.5));
				this.addInitializer(new Lifetime(4, 12));
				this.addInitializer(new Velocity(new DiscSectorZone(new Point(0, 0), 500, 0, -Math.PI, 0))); // was 200
				this.addInitializer(new Position(new DiscZone(new Point(0, 0), 2)));
				this.addInitializer(new ColorsInit([color1, color2]));
				this.addInitializer(new AlphaInit(1));
				
				this.addAction(new Accelerate(0, 400));
				this.addAction(new Age());
				this.addAction(new Move());
				this.addAction(new RotateToDirection());
				this.addAction(new LinearDrag(2));
				this.addAction(new AntiGravity(100, 100, 100, 4));
				this.addAction(new CircularAcceleration(100, 3));
				this.addAction(new RandomDrift(500));
		}
	}
}