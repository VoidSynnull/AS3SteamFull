/**
 * ...
 * @author Jordan, based on Smoke by Scott
 */

package game.particles.emitter 
{
	import flash.geom.Point;
	
	import engine.components.Spatial;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class CarExhaust extends Emitter2D
	{
		public function CarExhaust() 
		{
			
		}
		
		public override function update( time:Number ):void
		{
			// check direction of followTarget
			var newDirection:int = ( _followTarget.scaleX > 0 ) ? 1 : -1;
			if ( newDirection != _direction )
			{
				_direction = newDirection;
				changeDirection();
			}
			
			super.update( time );
		}
		
		public function init( followTarget:Spatial ):void
		{
			super.counter = new Random( 40, 60 );
			
			addInitializer( new ImageClass( Blob, [10, 0x333333], true ) );
			addInitializer( new AlphaInit( 0.4, 0.6 ));
			addInitializer( new Lifetime( 2, 4 ) ); 
			_velocityLineZone = new LineZone( new Point( -200, -50), new Point( -400, -150 ) );
			addInitializer( new Velocity( _velocityLineZone ) );
			addInitializer( new Position( new EllipseZone( new Point( 0,0 ), 4, 3)));
			
			addAction( new Age( Quadratic.easeOut ) );
			addAction( new Move() );
			addAction( new RandomDrift( 100, 100 ) );
			addAction( new ScaleImage( 1, 3 ) );
			addAction( new Fade(0.7, 0));
			_accelerate = new Accelerate( 50, -120);
			addAction( _accelerate );
			
			_followTarget = followTarget;
			_direction = 1;
			if ( _followTarget.scaleX < 0 )
			{
				_direction = -1;
				changeDirection();
			}
		}
		
		private function changeDirection():void
		{
			_velocityLineZone.startX *= -1;
			_velocityLineZone.endX *= -1;
			_accelerate.x *= -1;
		}
		
		private var _followTarget:Spatial;
		private var _direction:int;
		
		private var _velocityLineZone:LineZone
		private var _accelerate:Accelerate;
	}
}