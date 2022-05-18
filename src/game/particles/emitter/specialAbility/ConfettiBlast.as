package game.particles.emitter.specialAbility 
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Confetti;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ColorsInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.AntiGravity;
	import org.flintparticles.twoD.actions.CircularAcceleration;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Rotation;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	
	
	public class ConfettiBlast extends Emitter2D
	{	
		private const DEFAULT_COLORS:Array = [0xFF3E3E, 0xFF9900, 0xFBF404, 0x66FF00,0x0D91F2,0xA476D1,0xEF0065];
		
		public function ConfettiBlast() 
		{	
		}
		
		public function init( colors:Array = null, size:int = 5, counterNum:uint = 30 ):void
		{
			if( colors == null )
			{
				colors = DEFAULT_COLORS;
			}
			
			super.counter = new Blast( counterNum );

			addInitializer(new ImageClass(Confetti, [size], true));
			addInitializer( new Position( new DiscZone( new Point( 0, 0 ),4 ) ) );
			addInitializer( new ScaleImageInit( .5, 1.5) );
			addInitializer( new Rotation( 0, Math.PI * 2 ));
			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 675, 10, -Math.PI, 0 ) ) );
			addInitializer( new ColorsInit( colors ));
			addInitializer( new Lifetime( 12, 30 ) );
			addInitializer( new AlphaInit( 1 ) );	// NOTE :: For soem reason have to set alpha, otherwise it is zero?
			
			addAction( new Age() );
			addAction( new Move() );
			addAction( new RotateToDirection() );
			addAction( new Accelerate( 0, 320 ) );
			addAction( new LinearDrag( 2 ) );
			addAction( new AntiGravity(100, 100, 100, 4 ));
			addAction( new CircularAcceleration(100, 3) );
			addAction( new RandomDrift( 500 ) );
		}
	}
}