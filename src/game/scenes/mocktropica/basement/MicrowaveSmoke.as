package game.scenes.mocktropica.basement
{
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.TargetScale;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.ColorsInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.RotationAbsolute;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class MicrowaveSmoke extends Emitter2D
	{
		public function MicrowaveSmoke() { }
		
		public function init():void
		{
			this.counter = new Blast(24);
			
			this.addInitializer(new ImageClass(Blob, [4], true));
			this.addInitializer(new Position(new RectangleZone(-20, -40, 20, 0)));
			this.addInitializer(new ScaleImageInit(0.5, 1.5));
			this.addInitializer(new RotationAbsolute(-Math.PI/2, Math.PI/2));
			this.addInitializer(new Velocity(new RectangleZone(-10, -20, 10, 0)));
			this.addInitializer(new ColorsInit([0x111111, 0x222222, 0x333333]));
			this.addInitializer(new Lifetime(1, 2));
			
			this.addAction(new Age(Quadratic.easeIn));
			this.addAction(new TargetScale(3));
			this.addAction(new RandomDrift(50, 20));
			this.addAction(new Accelerate(0, -100));
			this.addAction(new Fade(0.8, 0));
			this.addAction(new Move());
		}
	}
}