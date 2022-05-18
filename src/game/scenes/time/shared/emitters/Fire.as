package game.scenes.time.shared.emitters
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Droplet;
	import org.flintparticles.common.easing.TwoWay;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.RotationAbsolute;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	/**
	 * 
	 * @author Scott Wszalek
	 */
	public class Fire extends Emitter2D
	{
		public function Fire()
		{
			
		}
		
		public function init(size:Number, box:RectangleZone, color:uint = 0xFFCC00 ):void
		{
			super.counter = new Steady(6);
			addInitializer(new ImageClass(Droplet, [size, color], true));
			addInitializer(new Lifetime(.4, .6));
			addInitializer(new Position(new LineZone(new Point(box.left, box.top), new Point(box.right, box.top))));
			addInitializer(new RotationAbsolute(1.5, 1.5));
			
			addAction(new Move());
			addAction(new Age(TwoWay.quadratic));
			addAction(new Fade(.8, 0));
			addAction(new ScaleImage(1, 0));
		}
	}
}