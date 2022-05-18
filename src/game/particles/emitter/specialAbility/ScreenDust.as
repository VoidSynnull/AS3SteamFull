package game.particles.emitter.specialAbility
{
	import flash.geom.Point;
	
	import fl.motion.easing.Quadratic;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class ScreenDust extends Emitter2D
	{
		public function ScreenDust()
		{
			super();
		}
		public function init():void
		{
			this.counter = new Blast(30);
			this.addInitializer(new Lifetime(0.8, 1.2));
			this.addInitializer(new Velocity(new LineZone(new Point(0, 70),new Point(0, 110))));
			this.addInitializer(new Position(new RectangleZone(0,0,950,450)));
			this.addInitializer(new ImageClass(Blob, [12,0x8F7A5F], true, 30));
			this.addAction(new Age(Quadratic.easeInOut));
			this.addAction(new Fade(0.6,0));
			this.addAction(new Move());
			this.addAction(new RotateToDirection());
		}
	}
}