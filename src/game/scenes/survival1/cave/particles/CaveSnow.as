package game.scenes.survival1.cave.particles
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	import game.util.BitmapUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class CaveSnow extends Emitter2D
	{
		public function CaveSnow()
		{
			this.start();
			
			this.counter = new Random(5, 10);
			
			
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(new Dot(2));
			
			// when using a BitmapRender you use SharedImage or SharedImages, since each particle is being draw to bitmap it only needs to be rendered once.
			this.addInitializer( new BitmapImage(bitmapData) );
			//this.addInitializer(new ImageClass(Dot,[2]));
			this.addInitializer(new ScaleImageInit(0.5, 1.5));
			
			this.addInitializer(new Position(new LineZone(new Point(-100, 0), new Point(100, 0))));
			this.addInitializer(new Velocity(new LineZone(new Point(0, 100), new Point(0, 200))));
			this.addInitializer(new Lifetime(5));
			
			this.addAction(new Age());
			this.addAction(new Move());
			this.addAction(new RandomDrift(100, 100));
		}
	}
}