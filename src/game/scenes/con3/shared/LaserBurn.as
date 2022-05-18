package game.scenes.con3.shared
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	import game.util.BitmapUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ColorChange;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class LaserBurn extends Emitter2D
	{
		public function LaserBurn()
		{
			this.counter = new Steady(25);
			
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(new Dot(3));
			
			this.addInitializer(new BitmapImage(bitmapData, true));
			this.addInitializer(new Position(new PointZone()));
			this.addInitializer(new Velocity(new DiscZone(new Point(), 200, 100)));
			this.addInitializer(new Lifetime(0.25));
			
			this.addAction(new ColorChange(0xFFFF7DB5, 0x66000000));
			this.addAction(new Move());
			this.addAction(new Age());
		}
	}
}