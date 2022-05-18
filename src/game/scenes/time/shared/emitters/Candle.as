package game.scenes.time.shared.emitters
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ColorChange;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Droplet;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.zones.DiscZone;
	
	
	public class Candle extends Emitter2D
	{	
		/**
		 * single flickering mote of fire 
		 */
		public function init():void
		{
			super.counter = new Steady( 30 );
			addInitializer( new Lifetime( 0.2, 0.4 ) );
			addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 0.8 ) ) );
			addInitializer( new ImageClass( Droplet, [-2,0xFFFF00], true) );
			
			addAction( new ScaleImage( 2, 0.2) );
			addAction( new Age( ) );
			addAction( new Move( ) );
			addAction( new LinearDrag( 1 ) );
			addAction( new Accelerate( 0, -30 ) );
			addAction( new ColorChange( 0xFFFF6600, 0x00CCFF00 ) );
			addAction( new RotateToDirection() );
			addAction( new Fade(1,0));
		}
		
		public function set rate(rate:int):void
		{
			Steady(super.counter).rate = rate;
		}
	}
}