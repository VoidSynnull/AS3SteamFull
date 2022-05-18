package game.scenes.poptropolis.javelin
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.RadialDot;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.zones.DiscZone;

	
	public class Dust extends Emitter2D
	{		
		public function init():void
		{
			
			counter = new Blast(300);
			
			addInitializer( new ImageClass( RadialDot, [1], true ) );
			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 100, 30, 90, 45 ) ) );
			addAction( new ScaleImage( 20, 2 ) );
			addInitializer( new ColorInit(0xFFC8AE69, 0xFFD8BC71) );
			addInitializer( new Lifetime( 3 ) );
			
			addAction( new Age() );
			addAction( new Move() );
			addAction( new Accelerate(1, 10) );
			addAction( new Fade( .5, 0 ) );
			addAction( new RandomDrift( 300, 50 ) );
		}
	}
}