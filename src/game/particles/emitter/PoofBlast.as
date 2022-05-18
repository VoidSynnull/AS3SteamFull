package game.particles.emitter
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	
	public class PoofBlast extends Emitter2D
	{
		public function PoofBlast()
		{
			super();
		}
		public function init(amount:int=20, size:Number = 6.5, color:uint = 0xffffff, lifeMin:Number = 0.2, lifeMax:Number = 0.3):void{
			this.counter = new Blast(amount);
			this.addInitializer(new Lifetime(lifeMin, lifeMax));
			this.addInitializer(new Velocity(new DiscSectorZone(new Point(0,0), 250, 180, -Math.PI, Math.PI )));
			this.addInitializer(new Position(new DiscZone(new Point(0,0), 18)));
			this.addInitializer(new ImageClass(Blob, [size,color], true, 6));
			this.addAction(new Age());
			this.addAction(new Move());
			this.addAction(new RotateToDirection());
			this.addAction(new Fade(0.8,0.1));
		}
	}
}