package game.scenes.deepDive1.shared.emitters
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	import game.util.BitmapUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class SubTrail extends Emitter2D
	{
		public function init():void
		{
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(new Dot(5));
			
			counter = new Random(5, 10);
			addInitializer( new BitmapImage(bitmapData) );
			addInitializer( new ScaleImageInit( .75, 1.25));
			addInitializer( new Lifetime( 1.5 ));//.75
			addInitializer( new Position( new LineZone( new Point( -40, 0 ), new Point( 40, 0 ))));
			addInitializer( new Velocity( new DiscZone(null, 40, 0)));
			addInitializer( new ColorInit(0x99a3d9ff, 0xfffffffff));

			addAction(new Age());
			addAction(new Move());
			addAction(new Fade());
			addAction( new Accelerate(0, -200 ));
		}
	}
}


