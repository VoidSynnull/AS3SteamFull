package game.particles.emitter.specialAbility 
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
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
	
	
	public class WhiteCloud extends Emitter2D
	{	
		public function WhiteCloud() 
		{	
		}
		
		public function init(dir:int):void
		{
			addInitializer( new Lifetime( 2, 2 ) );
			counter = new Blast( 20 );

			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 120, 10, -Math.PI*1.2, Math.PI*0.2) ) );
			addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 4 ) ) );
			addInitializer( new ImageClass( Blob, [12]) );
			addInitializer( new AlphaInit(0.8, 0.8));
			
			addAction( new Age( ) );
			addAction( new Fade(0.8, 0 ) );
			addAction( new Move( ) );
			addAction( new LinearDrag( 1 ) );
			addAction( new Accelerate( 50, 0 ) );
		
			addAction( new ScaleImage( 1, 4 ) );
			addAction( new RotateToDirection() );
		}
	}
}

