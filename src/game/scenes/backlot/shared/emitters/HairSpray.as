package game.scenes.backlot.shared.emitters
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.TargetScale;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.RadialEllipse;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class HairSpray extends Emitter2D
	{
		public function HairSpray() { }
		
		public function init():void
		{
			this.counter = new Steady(10);
			
			this.addInitializer(new ImageClass(RadialEllipse, [30, 30], true));
			this.addInitializer(new Position(new PointZone(new Point())));
			this.addInitializer(new Velocity(new PointZone(new Point(-80, 0))));
			this.addInitializer(new Lifetime(1));
			
			this.addAction(new Age(Quadratic.easeIn));
			this.addAction(new TargetScale(3));
			this.addAction(new RandomDrift(200, 200));
			this.addAction(new Accelerate(0, -150));
			this.addAction(new Fade(0.7, 0));
			this.addAction(new Move());
		}
	}
}