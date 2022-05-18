package game.scenes.viking.jungle
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	
	public class WoodChips extends Emitter2D
	{	
		public function WoodChips() {
			
		}
		
		public function init( bitmapData:BitmapData ):void
		{
			super.counter = new Blast( 5 );
			
			addInitializer( new BitmapImage(bitmapData) );
			addInitializer( new Lifetime( 12, 30 ) );;
			super.addInitializer( new Velocity( new DiscZone( new Point( 0, 0 ), 400, 10 ) ) );
			addInitializer( new ScaleImageInit( 0.4, .7) );
			
			addAction( new Age( ) );
			addAction( new Move( ) );
			addAction( new RotateToDirection() );
			addAction( new Accelerate( 0, 400 ) );
		}
		
		public function set rate(rate:int):void
		{
			Steady(super.counter).rate = rate;
		}
	}
}