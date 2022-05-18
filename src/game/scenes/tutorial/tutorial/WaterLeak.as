package game.scenes.tutorial.tutorial
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class WaterLeak extends Emitter2D
	{
		public function init():void
		{
			counter = new Steady(10);
			
			addInitializer( new ImageClass( Dot, [2], true ));
			addInitializer( new Position( new LineZone( new Point( -15, 0 ), new Point( 15, 0 ))));
			addInitializer( new Velocity( new PointZone( new Point( 0, 0 ))));
			addInitializer( new ScaleImageInit( 1, 2));
			addInitializer( new ColorInit(0xFF4da6da, 0xFF8ecbee));
			addInitializer( new Lifetime( 1.69 ));
			
			addAction( new Age());
			addAction( new Move());
			addAction( new Accelerate(0, 400 ));
		}
	}
}