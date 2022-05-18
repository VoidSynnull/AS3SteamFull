/**
 * Creates a swarm of flies that will fly around a specified point (usually a garbage can)
 * @author Jordan
 */

package game.particles.emitter
{
	import flash.geom.Point;
	
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Ellipse;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.ApproachNeighbours;
	import org.flintparticles.twoD.actions.BoundingBox;
	import org.flintparticles.twoD.actions.GravityWell;
	import org.flintparticles.twoD.actions.MinimumDistance;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.actions.SpeedLimit;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.EllipseZone;
	//import org.flintparticles.twoD.zones.RectangleZone;
	
	public class SwarmingFlies extends Emitter2D
	{
		public function init(originPoint:Point, numFlies:Number = 10):void
		{
			counter = new Blast( numFlies );	
			addInitializer( new ImageClass( Ellipse, [8, 4], true ) );
			//addInitializer( new Position( new RectangleZone( 900, 900, 1100, 1100 ) ) );
			addInitializer( new Position( new EllipseZone( new Point ( originPoint.x, originPoint.y ), 100, 100 ) ) );
			addInitializer( new Velocity( new DiscZone( new Point( 0, 0 ), 150, 100 ) ) );
			addInitializer( new ScaleImageInit( .5, 1) );
			addInitializer( new ColorInit(0xFF000000, 0xFF333333) );
			
			addAction( new ApproachNeighbours( 50, 100 ) );
			//addAction( new MatchVelocity( 20, 200 ) );
			addAction( new MinimumDistance( 5, 200 ) );
			addAction( new SpeedLimit( 100, true ) );
			addAction( new RotateToDirection() );
			addAction( new BoundingBox( originPoint.x-100, originPoint.y-100, originPoint.x+100, originPoint.y+100 ) );
			addAction( new SpeedLimit( 200 ) );
			addAction( new RandomDrift( 500, 500 ) );
			addAction( new GravityWell( 130, originPoint.x, originPoint.y, 50 ) );
			addAction( new Move() );
		}
	}
}