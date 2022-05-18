package game.particles.emitter.specialAbility 
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.RadialDot;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	
	
	public class SnowBlast extends Emitter2D
	{	
		
		public function SnowBlast() 
		{	
	
		}
		
		public function init():void
		{
			super.counter = new Blast( 75 );
			addInitializer( new Lifetime( 12, 14 ) );
			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 55, 10, -Math.PI, 0 ) ) );
			addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 12 ) ) );
			addInitializer( new ImageClass( RadialDot, [3, 0xFFFFFF], true ) );
			addInitializer( new ScaleImageInit( .5, 1.5) );
			
			addAction( new Age( ) );
			addAction( new Move( ) );
			addAction( new LinearDrag( 1 ) );
			addAction( new Accelerate( 0, -40 ) );
			addAction( new RotateToDirection() );
			addAction( new Accelerate( 0, 200 ) );
			addAction( new LinearDrag( 0.5 ) );
		}
		
		
	}
	

}