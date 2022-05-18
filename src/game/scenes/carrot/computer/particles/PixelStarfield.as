/**
 * ...
 * @author Bard
 */

 package game.scenes.carrot.computer.particles 
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	import org.flintparticles.common.counters.Counter;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Rect;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.twoD.zones.Zone2D;

	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	
	public class PixelStarfield extends Emitter2D
	{	
		//public function init( size:int, color:Number, velocityZone:Zone2D, positionZone:Zone2D ):void
		public function init( size:int, color:uint, velocity:int, positionZone:Zone2D, deathArea:DisplayObjectContainer ):void
		{
			super.counter = new Random( 15, 18 );

		    addInitializer( new ImageClass( Rect, [size, size, color], true ) );
			addInitializer( new Lifetime( 1, 2 ) ); 
			addInitializer( new AlphaInit( .1, .5 ) );
			addInitializer( new Velocity( new PointZone( new Point(0, velocity) ) ) );
			addInitializer( new Position( positionZone ) );
		  
		    addAction( new Move() );
			addAction( new DeathZone( new RectangleZone( 0, 0, deathArea.width, deathArea.height ),true));
		}
	}
}

