package game.scenes.backlot.shared.emitters
{
	import flash.geom.Point;
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Droplet;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ColorsInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Rotation;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class RainEmitter extends Emitter2D
	{
		public function RainEmitter() { }
		
		public function init( rate:int = 100, lifeTime:Number = .675, vel:Number = 500, acc:Number = 1000 ):void
		{
			this.counter = new Steady(rate);
			
			this.addInitializer(new ImageClass(Droplet, [2.5], true));
			this.addInitializer(new Position(new LineZone(new Point(0, 0), new Point(650, 0))));
			this.addInitializer(new Velocity(new PointZone(new Point(0, vel))));
			this.addInitializer(new Rotation(Math.PI / 2));
			//like to figure out how to change color, but color and colors init dont work
			//this.addInitializer(new ColorInit(0x00CCFF,0x0000FF));
			//they just make the particle disapear
			this.addInitializer(new ScaleImageInit(0.5, 1));
			this.addInitializer(new Lifetime(lifeTime));
			
			this.addAction(new Age());
			this.addAction(new Move());
			this.addAction( new Accelerate(0, acc));
		}
	}
}