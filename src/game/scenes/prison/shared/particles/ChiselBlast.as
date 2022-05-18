package game.scenes.prison.shared.particles
{
	import flash.geom.Point;
	
	import game.util.GeomUtils;
	
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class ChiselBlast extends Emitter2D
	{
		public function init(min:Number=3, max:Number=8, size:Number = 20, color:uint = 0xFFFFFF):void
		{
			this.counter = new Blast(GeomUtils.randomInRange(min,max));
			
			addInitializer(new ImageClass(Blob, [size, color], true));
			addInitializer(new Position(new RectangleZone(-15,-15,15,15)));
			addInitializer(new Velocity(new DiscZone(new Point(0,0), 150)));
			
			addAction(new Accelerate(0, 400));
			addAction(new Move());
		}
	}
}