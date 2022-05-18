/**
 * ...
 * @author Bard
 */

 package game.particles.emitter.characterAnimations 
{
	import engine.components.Spatial;
	import flash.geom.Point;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.twoD.actions.AntiGravity;
	import org.flintparticles.twoD.actions.RandomDrift;

	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Blast;
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
	
	public class Breath extends Emitter2D
	{
		public function Breath() 
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
		
		public function init( followTarget:Spatial, xOffset:int = 0 ):void
		{
			super.counter = new Random( 6, 12 );

		    addInitializer( new ImageClass( Dot,[3],true ) );
		    addInitializer( new ScaleImageInit( .6, 1) );
			addInitializer( new AlphaInit( .3, .4 ));
			addInitializer( new Lifetime( 1, 1.4 ) );
			_positionLineZone = new LineZone( new Point( xOffset - 6, 2), new Point( xOffset + 6, -2 ) );
			addInitializer( new Position( _positionLineZone ) );
			_velocityLineZone = new LineZone( new Point( -10, 10), new Point( -20, 20 ) );
			addInitializer( new Velocity( _velocityLineZone ) );
		  
			addAction( new Age( Quadratic.easeOut ) );
		    addAction( new Move() );
		    addAction( new RandomDrift( 10, 10 ) );
			addAction( new AntiGravity( 10 ) );
			addAction( new ScaleImage( 1, 1.75 ) );
			addAction( new Fade( .4, 0 ) );
			_accelerate =  new Accelerate( 0, -40);
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
			_positionLineZone.startX *= -1;
			_positionLineZone.endX *= -1;
			_accelerate.x *= -1;
		}
		
		private var _followTarget:Spatial;
		private var _direction:int;

		private var _velocityLineZone:LineZone
		private var _positionLineZone:LineZone
		private var _accelerate:Accelerate;
	}
}

