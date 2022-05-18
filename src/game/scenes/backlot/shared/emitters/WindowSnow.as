package game.scenes.backlot.shared.emitters
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class WindowSnow extends Emitter2D
	{
		public function WindowSnow() { }
		
		public function init():void
		{
			this.counter = new Steady(100);
			
			this.addInitializer(new ImageClass(Blob, [2.5], true));
			this.addInitializer(new Position(new LineZone(new Point(0, 0), new Point(30, -315))));
			this.addInitializer(new Velocity(new RectangleZone(-450, 30, -300, 60)));
			this.addInitializer(new ScaleImageInit(0.5, 1.5));
			this.addInitializer(new Lifetime(1.8));
			
			this.addAction(new Age(Quadratic.easeIn));
			this.addAction(new RandomDrift(200, 100));
			this.addAction(new Move());
		}
	}
}