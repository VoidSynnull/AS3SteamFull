package game.particles.emitter.specialAbility
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Ring;
	import org.flintparticles.common.easing.Sine;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class MagicBubbleBlast extends Emitter2D
	{
		public function MagicBubbleBlast()
		{
		}
		
		public function init(bitmapData:BitmapData = null, counterNum:uint = 30, area:RectangleZone = null, size:int = 10, color:uint = 0x66FFFF):void
		{
			if(!area) area = new RectangleZone(-90, -80, 90, 30);
			
			if(bitmapData) addInitializer(new BitmapImage(bitmapData, true));
			else addInitializer(new ImageClass(Ring, [size, size+1, color], false));
			
			this.counter = new Blast(counterNum);	
			addInitializer(new Position(area));
			addInitializer(new Velocity(new PointZone(new Point(0, -30))));
			addInitializer(new Lifetime(1,1));
			addInitializer(new ScaleImageInit(.5, 1));
			addInitializer(new AlphaInit(1));
			
			addAction(new Accelerate(0, -400));
			addAction(new Age(Sine.easeIn));
			addAction(new Move());
			addAction(new ScaleImage(1, 2));
			addAction(new Fade(1, 0));
		}
	}
}