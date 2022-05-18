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
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	
	
	public class SmokeBlast extends Emitter2D
	{	
		
		public function SmokeBlast() 
		{	
	
		}
		
		public function init():void
		{
			counter = new Steady( 10 );
			addInitializer( new Lifetime( 11, 12 ) );
			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 40, 30, -4 * Math.PI / 7, -3 * Math.PI / 7 ) ) );
			addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 14 ) ) );
			addInitializer( new ImageClass( Blob, [7, 0x888888], true) );
			
			addAction( new Age( ) );
			addAction( new Move( ) );
			addAction( new LinearDrag( 0.01 ) );
			addAction( new ScaleImage( 1, 15 ) );
			addAction( new Fade( 0.15, 0 ) );
			addAction( new RandomDrift( 15, 15 ) );
		}
		
		
		public function stopEmitter():void{
			counter = new Steady(0);
		}
		
	}
	

}