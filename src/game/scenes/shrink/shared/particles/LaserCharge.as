package game.scenes.shrink.shared.particles
{
	import flash.geom.Point;
	
	import game.util.BitmapUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.GravityWell;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.zones.DiscZone;
	
	public class LaserCharge extends Emitter2D
	{
		public function LaserCharge()
		{
			super();
		}
		
		public var lifeTime:Number;
		
		public function init(color1:uint = 0x00FF00, color2:uint = 0x99FF99, rate:int = 50, lifeTime:Number = .5, vel:Number = 50):void
		{
			this.lifeTime = lifeTime;
			this.counter = new Steady(rate);
			
			this.addInitializer(new BitmapImage(BitmapUtils.createBitmapData(new Dot(5)),true));
			this.addInitializer(new Position(new DiscZone(new Point(),vel)));
			color = new ColorInit(color1, color2);
			this.addInitializer(color);
			this.addInitializer(new AlphaInit());
			this.addInitializer(new ScaleImageInit(0.5, 1));
			this.addInitializer(new Lifetime(lifeTime));
			
			this.addAction(new Age());
			this.addAction(new Move());
			this.addAction(new Fade(1,0));
			this.addAction(new GravityWell(vel * 10,0,0,vel / lifeTime))
		}
		
		private var color:ColorInit;
		
		public function setColor(color1:uint = 0x00FF00, color2:uint = 0x99FF99):void
		{
			color.minColor = color1;
			color.maxColor = color2;
		}
	}
}