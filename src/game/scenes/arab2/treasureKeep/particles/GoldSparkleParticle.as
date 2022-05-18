package game.scenes.arab2.treasureKeep.particles
{
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	
	import game.util.BitmapUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class GoldSparkleParticle extends Emitter2D
	{
		public function init($particleClip:DisplayObjectContainer, position:RectangleZone, rate:Number = 30):void
		{
			var bitmapData:BitmapData = BitmapUtils.createBitmapData($particleClip, 0.5);
			
			super.addInitializer(new BitmapImage(bitmapData, true));
			
			super.addInitializer(new Position(position));
			super.addInitializer(new Lifetime( 1.2, 0.5 ));
			
			super.addAction( new Fade());
			super.addAction( new Age() );
			
			super.counter = new Steady(rate);
		}
	}
}

