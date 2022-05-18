package game.particles.emitter
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import org.flintparticles.common.counters.Counter;
	import org.flintparticles.common.displayObjects.Droplet;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.RotationAbsolute;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Drip extends Emitter2D
	{
		public function init(counter:Counter, size:Number, color:uint, safeZone:Rectangle, xSpeed:Number = 0):void
		{
			this.counter = counter;
			addInitializer(new ImageClass(Droplet, [size, color], true));
			addInitializer(new Position(new RectangleZone(safeZone.left, safeZone.top, safeZone.left+2, safeZone.top+2)));
			addInitializer(new Velocity(new LineZone(new Point(xSpeed, 300), new Point(xSpeed, 400))));
			addInitializer(new RotationAbsolute(1.5, 1.5));
			
			addAction(new Move());
			addAction(new DeathZone(new RectangleZone(safeZone.left, safeZone.top, safeZone.right, safeZone.bottom), true));
		}
	}
}