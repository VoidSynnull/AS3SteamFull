package game.scenes.hub.avatarShop
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class MachineSteam extends Emitter2D
	{
		public function MachineSteam()
		{
			this.counter = new Steady(30);
			
			this.addInitializer(new ImageClass(Blob, [6], true));
			this.addInitializer(new Position(new PointZone(new Point(-70, -74))));
			this.addInitializer(new Velocity(new RectangleZone(-120, -20, -60, 20)));
			this.addInitializer(new ScaleImageInit(0.5, 1));
			this.addInitializer(new Lifetime(1));
			
			this.addAction(new Age());
			this.addAction(new Move());
			this.addAction(new Fade(0.5, 0));
			this.addAction(new RandomDrift(50, 50));
			this.addAction(new Accelerate(0, -170));
		}
	}
}