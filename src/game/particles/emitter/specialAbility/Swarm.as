package game.particles.emitter.specialAbility 
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	
	
	public class Swarm extends Emitter2D
	{	
		public function Swarm() 
		{	
		}
		
		public function init(dir:int):void
		{
			super.counter = new Blast( 45 );
			addInitializer( new Lifetime( 4, 4 ) );
			counter = new Blast( 22 );
			
			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 200, 10, -Math.PI*1.2, Math.PI*0.2) ) );
			addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 4 ) ) );
			addInitializer( new AlphaInit(1,1));
			
			addAction( new Age( ) );
			addAction( new Move( ) );
			addAction( new LinearDrag( 1 ) );
			//addAction( new Accelerate( -50, 0 ) );
					}
	}
}

