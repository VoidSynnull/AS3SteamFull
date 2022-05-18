package game.scenes.time.shared.emitters
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Boomerang;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Jet;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Wind extends Emitter2D
	{
		public function init(size:Number, location:Rectangle):void
		{
			super.counter = new Steady(20);
			addInitializer(new ImageClass(Boomerang, [size, 0xFFFFFF], true));
			addInitializer(new AlphaInit(.4, .7));
			addInitializer(new Position(new LineZone(new Point(location.left, size), new Point(location.right - size, size))));
			addInitializer(new Velocity(new LineZone(new Point(0, -600), new Point(0, -800))));
			addInitializer(new Lifetime(.1, .25));
			
			addAction(new Age());
			addAction(new Move());
			addAction(new Jet(0, -100, new RectangleZone(location.left, location.top, location.right, location.bottom)));
		}
	}
}