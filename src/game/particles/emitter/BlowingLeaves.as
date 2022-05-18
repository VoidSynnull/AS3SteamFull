/**
 * Creates leaves blowing by in the wind
 * @author Jordan
 */

package game.particles.emitter
{
	import flash.geom.Point;
	
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Ellipse;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.CircularAcceleration;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.RectangleZone;

	public class BlowingLeaves extends Emitter2D
	{		
		public function init(startLineZone:LineZone = null, startVelocity:Point = null, allowedZone:RectangleZone = null):void
		{
			if (startLineZone == null) {
				startLineZone = new LineZone( new Point( 0, 0 ), new Point( 0, 1000 ) );
			}
			if (startVelocity == null) {
				startVelocity = new Point( 300, 50 );
			}
			if (allowedZone == null) {
				allowedZone = new RectangleZone( -50, -50, 1000, 1000 );
			}
			
			counter = new Steady(3);
			
		    addInitializer( new ImageClass( Ellipse, [6, 4], true ) );
		    addInitializer( new Position( startLineZone ) );
		    addInitializer( new Velocity( new PointZone( startVelocity ) ) );
		    addInitializer( new ScaleImageInit( .5, 1.5) );
			addInitializer( new ColorInit(0xFF2D7148, 0xFFBAAB69) );
			//addInitializer( new Lifetime( 3 ) );
		  	
			//addAction( new Age() );
		    addAction( new Move() );
		    addAction( new DeathZone( allowedZone, true ) );
		    addAction( new RandomDrift( 200, 600 ) );
			//addAction( new Jet(200, 0, new RectangleZone( 0, 900, 4420, 1500 ), false)); //removed since no longer falling from above
			addAction( new RotateToDirection() );
			addAction( new Accelerate(0, 50) );
			addAction( new CircularAcceleration( 400, -3 ) );
		}
	}
}