/**
 * ...
 * @author billy
 */

package game.particles.emitter.characterAnimations 
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Dot;
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
	
	public class Tears extends Emitter2D
	{
		public function Tears() 
		{
			
		}
		
		public function init(direction:int):void
		{
			
			super.counter = new Steady(1);

		    addInitializer( new ImageClass( Dot,[3],true ) );
		    addInitializer( new Position( new LineZone( new Point( -15, -5 ), new Point( 15, 5 ) ) ) );
		    addInitializer( new Velocity( new PointZone( new Point( 75 * direction, -75 ) ) ) );
		    addInitializer( new ScaleImageInit( .5, 1) );
			addInitializer( new Lifetime( 1.2, 1.5 ) );
		  
			addAction( new Age() );
		    addAction( new Move() );
		    //addAction( new DeathZone( new RectangleZone( -250, -250, 250, 35 ), true ) );
		    //addAction( new RandomDrift( 15, 15 ) );
			addAction( new Accelerate(0, 200) );
		}
		
		public function set rate(rate:int):void
		{
			Steady(super.counter).rate = rate;
		}
	}
}