package game.particles.emitter
{
	import flash.geom.Rectangle;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.counters.TimePeriod;
	import org.flintparticles.common.displayObjects.Ring;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.ScaleAll;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Ripple extends Emitter2D
	{
		public var ripples:int;
		public var lifeTime:Number;
		public function Ripple()
		{
			super();
		}
		
		public function init(ripples:int = 1, lifeTime:Number = 1, radius:Number = 25, thickness:Number = 1, maxScale:Number = 1, color:uint = 0xffffff, steady:Boolean = false, zone:Rectangle = null):void
		{
			this.ripples = ripples;
			this.lifeTime = lifeTime;
			if(steady)// constantly spawns ripples
				this.counter = new Steady(ripples);
			else// spawns a set number of ripples over a period of time
				this.counter = new TimePeriod(ripples, lifeTime);
			
			//spawns at emitters location
			if(zone == null)
				zone = new Rectangle();
			//else spawns within an area
			
			this.addInitializer(new Lifetime(lifeTime * ripples));
			this.addInitializer(new ImageClass(Ring, [radius, radius+thickness, color]));
			this.addInitializer(new Position(new RectangleZone(zone.left, zone.top, zone.right, zone.bottom)));
			this.addAction(new Age());
			this.addAction(new ScaleAll(0, maxScale));
			this.addAction(new Fade(0.8,0.1));
		}
	}
}