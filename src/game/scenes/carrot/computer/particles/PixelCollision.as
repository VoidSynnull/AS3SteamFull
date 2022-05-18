/**
 * ...
 * @author Bard
 */

 package game.scenes.carrot.computer.particles 
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Friction;
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
	
	public class PixelCollision extends Emitter2D
	{	
		//public function init( size:int, color:Number, velocityZone:Zone2D, positionZone:Zone2D ):void
		public function init( size:int, blastNum:int, velocityZone:Zone2D, deathArea:DisplayObjectContainer ):void
		{
			super.counter = new Blast( blastNum )
			
		    addInitializer( new ImageClass( Rect, [size, size], true ) );
			addInitializer( new Lifetime( .5, .75 ) ); 
			addInitializer( new Velocity( velocityZone ) );
		  
			addAction( new Age( Quadratic.easeOut ) );
		    addAction( new Move() );
			addAction( new Fade( 1, 0 ) );
			addAction( new DeathZone( new RectangleZone( 0, 0, deathArea.width, deathArea.height ), true));
			addAction( new Friction( 200 ) );
		}
	}
}

