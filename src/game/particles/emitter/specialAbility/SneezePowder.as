package game.particles.emitter.specialAbility 
{	
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.AntiGravity;
	import org.flintparticles.twoD.actions.CircularAcceleration;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	
	
	public class SneezePowder extends Emitter2D
	{	
		
		public function SneezePowder() 
		{	
		}
		
		public function init(speedX:Number = 0):void
		{
			super.counter = new Blast( 400 );
			addInitializer( new Lifetime(7, 15) );
			addInitializer( new Velocity( new DiscSectorZone( new Point( speedX, 0 ), 85, 10, -Math.PI, Math.PI ) ) );
			addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 8 ) ) );
			addInitializer( new ImageClass( Dot, [1, 0xFFFFFF], true ) );
			addInitializer( new ScaleImageInit( .9, 1.1) );
			
			addAction( new Accelerate(0, -30) );
			addAction( new Age() );
			addAction( new Move() );
			addAction( new Fade(1, 0));
			addAction( new LinearDrag(.2) );
			addAction( new AntiGravity(20) );
			addAction( new CircularAcceleration(100, 3) );
		}
	}
}