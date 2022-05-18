package game.scenes.con3.shared.particles
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
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	
	public class ArrowExplosion extends Emitter2D
	{
		public function ArrowExplosion()
		{
			super();
		}
		
		public function init():void
		{
			counter = new Blast( 8 );
			addInitializer( new Lifetime( 0.6, 0.8 ) );
			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 120, 80, 0, 180 ) ) );
			addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 14 ) ) );
			addInitializer( new ImageClass( Blob, [6, 0x8CD547], true) );
			addInitializer(new AlphaInit(0.8,0.8));
			
			addAction( new Age( ) );
			addAction( new Move( ) );
			addAction( new LinearDrag( 0.01 ) );
			addAction( new ScaleImage( 1, 4 ) );
			addAction( new Fade( 0.8, 0 ) );
			addAction( new RandomDrift( 15, 15 ) );					
		}
	}
}