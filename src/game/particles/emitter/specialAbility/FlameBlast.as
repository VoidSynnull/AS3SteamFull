package game.particles.emitter.specialAbility 
{
	import flash.geom.Point;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ColorChange;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.common.displayObjects.Blob;
	
	
	public class FlameBlast extends Emitter2D
	{	
		
		public function FlameBlast() 
		{	
	
		}
		
		public function init():void
		{
			super.counter = new Blast( 55 );
			addInitializer( new Lifetime( 1, 2.5 ) );
			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 28, 10, -Math.PI, 0 ) ) );
			addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 18 ) ) );
			addInitializer( new ImageClass( Blob, [5], true) );
			
			addAction( new Age( ) );
			addAction( new Move( ) );
			addAction( new LinearDrag( 1 ) );
			addAction( new Accelerate( 0, -100 ) );
			addAction( new ColorChange( 0xFFFF7700, 0x00CC0000 ) );
			addAction( new ScaleImage( 0.3, 0.1 ) );
			addAction( new RotateToDirection() );

		}
		
		
	}
	
}