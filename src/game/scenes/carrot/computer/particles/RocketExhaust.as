/**
 * ...
 * @author Bard
 */

 package game.scenes.carrot.computer.particles 
{
	import flash.display.BitmapData;
	
	import game.util.BitmapUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ColorMultiChange;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Counter;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.data.ColorStep;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.Zone2D;
	
	public class RocketExhaust extends Emitter2D
	{	
		public function init( size:int, velocityZone:Zone2D, positionZone:Zone2D, counterType:Counter = null ):void
		{
			//super.counter = ( counter == null ) ? new Random( 10, 20 ) : counter;

			if(counterType == null)
			{
				super.counter = new Random(10, 20);
			}
			else
			{
				super.counter = counterType;
			}
			
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(new Blob(size));
			
		    addInitializer( new BitmapImage( bitmapData, true ) );
		    addInitializer( new ScaleImageInit( .8, 1.2) );
			addInitializer( new AlphaInit( .8, 1 ));
			addInitializer( new Lifetime( 2, 3 ) ); 
			addInitializer( new Velocity( velocityZone ) );
			addInitializer( new Position( positionZone ) );
		  
			addAction( new Age( Quadratic.easeOut ) );
			//addAction( new Age(Quadratic.easeIn) );
		    addAction( new Move() );
		    addAction( new RandomDrift( 100, 100 ) );
			addAction( new ScaleImage( 1, 2 ) );
			addAction( new Fade( 1, 0 ) );
			addAction( new ColorMultiChange( new ColorStep( 0xFFCC00, 1), new ColorStep( 0xBC350E, .8), new ColorStep( 0xFFFFFF, .3) ) );
		}
	}
}

