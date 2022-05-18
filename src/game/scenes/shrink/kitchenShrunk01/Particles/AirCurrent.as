package game.scenes.shrink.kitchenShrunk01.Particles
{
	import flash.geom.Point;
	
	import game.util.BitmapUtils;
	import game.util.PointUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Rotation;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class AirCurrent extends Emitter2D
	{
		public function AirCurrent()
		{
			super();
		}
		
		public function init(rate:int = 10, lifeTime:Number = 1, width:Number = 100, velx:Number = 0, velY:Number = -100):void
		{
			this.counter = new Steady(rate);
			
			this.addInitializer(new BitmapImage(BitmapUtils.createBitmapData(new Air()), true));
			
			this.addInitializer(new Velocity(new PointZone(new Point(velx, velY))));
			
			var rotation:Number = PointUtils.getRadiansOfTrajectory(new Point(velx, velY));
			
			this.addInitializer(new Position(new LineZone(new Point(Math.sin(rotation) * -width / 2, Math.cos(rotation) * -width / 2), new Point(Math.sin(rotation) * width / 2, Math.cos(rotation) * width / 2))));
			this.addInitializer(new Rotation(rotation));
			
			this.addInitializer(new ColorInit());
			this.addInitializer(new AlphaInit(0,.5));
			this.addInitializer(new ScaleImageInit(2, 1));
			this.addInitializer(new Lifetime(lifeTime));
			
			this.addAction(new Age());
			this.addAction(new Move());	
			this.addAction(new Fade(.5))
		}
	}
}