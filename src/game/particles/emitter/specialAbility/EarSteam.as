package game.particles.emitter.specialAbility 
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.PointZone;
	
	
	public class EarSteam extends Emitter2D
	{	
		
		private var xDir : Number = -1;
		
		public function EarSteam(xD:Number=-1) 
		{	
			xDir = xD;
		}
		
		public function init():void
		{
			counter = new Steady( 10 );
			addInitializer( new Lifetime( 2.4, 3 ) );
			addInitializer( new Velocity( new PointZone( new Point(xDir*200, 0) ) ) );
			addInitializer( new Position( new DiscZone( new Point( xDir*80, -10 ), 4 ) ) );
			addInitializer( new ImageClass( Blob, [7, 0x888888], true) );
			
			addAction( new Age( ) );
			addAction( new Move( ) );
			addAction( new LinearDrag( 0.01 ) );
			addAction( new ScaleImage( 1, 15 ) );
			addAction( new LinearDrag( 0.5 ) );
			addAction( new Accelerate( 0, -30 ) );
			addAction( new Fade( 0.3, 0.001 ) );
			addAction( new RandomDrift( 15, 15 ) );
		}
		
		
		public function stopEmitter():void{
			counter = new Steady(0);
		}
		
	}
	

}