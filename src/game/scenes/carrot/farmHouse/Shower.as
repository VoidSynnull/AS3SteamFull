/**
 * ...
 * @author billy
 */

package game.scenes.carrot.farmHouse
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;

	public class Shower extends Emitter2D
	{		
		public function init():void
		{
			counter = new Steady(20);
			
			addInitializer( new ImageClass( Dot, [2], true ));
			addInitializer( new Position( new LineZone( new Point( -12, 0 ), new Point( 12, 0 ))));
			addInitializer( new Velocity( new PointZone( new Point( 0, -15 ))));
			addInitializer( new ScaleImageInit( 1, 2));
			addInitializer( new ColorInit(0xFF008800, 0xFF00FA00));
			addInitializer( new Lifetime( .75 ));
			
			addAction( new Age());
			addAction( new Move());
			addAction( new Accelerate(0, 650 ));
		}
	}
}