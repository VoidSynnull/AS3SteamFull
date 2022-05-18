package game.scenes.virusHunter.stomach.particles
{
	import flash.geom.Point;
	
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class StomachDrink extends Emitter2D
	{		
		public function init(x:Number, y:Number):void
		{
			this.counter = new Steady(50);
			
			this.addInitializer(new ImageClass(Blob, [20], true));
			this.addInitializer(new Position(new PointZone(new Point(x, y))));
			this.addInitializer(new Velocity(new RectangleZone(300, 0, 500, 0)));
			this.addInitializer(new ScaleImageInit(1, 2));
			this.addInitializer(new ColorInit(0xDD7C307C, 0xDD7C307C));
			
			this.addAction(new Move());
			this.addAction(new DeathZone( new RectangleZone(0, 0, 3065, 1340), true));
			//this.addAction(new RandomDrift(0, 200));
			this.addAction(new Accelerate(0, 450));
		}
	}
}