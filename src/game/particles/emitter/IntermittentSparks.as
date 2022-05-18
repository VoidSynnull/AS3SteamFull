/**
 * ...
 * @author billy
 */

package game.particles.emitter
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Pulse;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;

	public class IntermittentSparks extends Emitter2D
	{		
		public function init():void
		{
			counter = new Pulse(3, 20);
				  
		    addInitializer( new ImageClass( Dot, [1], true ) );
		    addInitializer( new Position( new LineZone( new Point( -10, 10 ), new Point( 10, 10 ) ) ) );
		    addInitializer( new Velocity( new LineZone( new Point( -200, -400 ), new Point( 200, 0 ) ) ) );
		    addInitializer( new ScaleImageInit( .5, 2) );
			addInitializer( new ColorInit(0xFFffff66, 0xFFffcc00) );
			addInitializer( new Lifetime( 3 ) );
		  	
			addAction( new Age() );
		    addAction( new Move() );
		    addAction( new RandomDrift( 400, 200 ) );
			addAction( new Accelerate(0, 400) );
			addAction( new Fade(1, 0) );
		}
	}
}