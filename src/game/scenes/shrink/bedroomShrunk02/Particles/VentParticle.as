package game.scenes.shrink.bedroomShrunk02.Particles
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class VentParticle extends Emitter2D
	{
		public function VentParticle()
		{
			super();
		}
		
		public function init( rate:int = 10, width:Number = 250, acc:Number = -100):void
		{
			this.counter = new Random(0, rate);
			
			this.addInitializer(new ImageClass(Blob,null, true));
			this.addInitializer(new Position(new LineZone(new Point(-width / 2, 0), new Point(width / 2, 0))));
			this.addInitializer(new Velocity(new PointZone(new Point(0, acc))));
			this.addInitializer(new Lifetime(2, 5));
			this.addInitializer(new ColorInit());
			this.addInitializer(new AlphaInit());
			
			this.addAction(new Age());
			this.addAction(new Move());
			this.addAction(new Fade());
			this.addAction(new Accelerate(0, acc));
		}
	}
}