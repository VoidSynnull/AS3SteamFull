package game.particles.emitter.specialAbility
{
	import flash.geom.Point;
	
	import engine.components.Spatial;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.LineZone;
	
	/**
	 * Shoot sparks behind skateboard (this doesn't work on the web for some reason) 
	 */
	public class ShootSparks extends Emitter2D
	{
		public function ShootSparks()
		{
		}
		
		public function init(followTarget:Spatial, centerX:Number, centerY:Number, radius:Number):void
		{
			_followTarget = followTarget;
			_centerX = centerX;
			_centerY = centerY;
			
			_direction = 1;
			if ( _followTarget.scaleX < 0 )
				_direction = -1;
				
			super.counter = new Steady( 120 );
			addInitializer( new AlphaInit( 1, 1 )); 

			addInitializer( new Lifetime( 0.3, 0.5 ) ); 
			_velocityLineZone = new LineZone( new Point(_direction * 200, 0), new Point( _direction * 200, 0 ) );
			addInitializer( new Velocity( _velocityLineZone ) );
			_discZone = new DiscZone( new Point(_direction * centerX, centerY), radius );
			addInitializer( new Position( _discZone ) );
			
			addAction( new Age( Quadratic.easeOut ) );
			addAction( new Move() );
			addAction( new Fade( ) );
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
		
		private function changeDirection():void
		{
			_velocityLineZone.startX *= -1;
			_velocityLineZone.endX *= -1;
			_discZone.centerX *= -1;
		}
		
		private var _followTarget:Spatial;
		private var _direction:int;
		
		private var _velocityLineZone:LineZone
		private var _discZone:DiscZone;
		private var _centerX:Number;
		private var _centerY:Number;
	}
}