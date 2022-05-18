
package game.scenes.arab1.shared.particles
{
	import flash.geom.Point;
	
	import game.util.PerformanceUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class Sand extends Emitter2D
	{		
		public function Sand() 
		{
			
		}
		
		public override function update( time:Number ):void
		{			
			
			super.update( time );
		}
		
		public function init( color:uint = 0xB59555 ):void
		{
			if(PerformanceUtils.QUALITY_HIGH <= PerformanceUtils.qualityLevel){
				super.counter = new Random(5, 10);
			}
			else{
				super.counter = new Steady(7);
			}
			
			addInitializer( new ImageClass( Blob, [3,color], true ) );
			addInitializer( new ScaleImageInit( .8, 1.0) );
			addInitializer( new AlphaInit( .6, 1 ));
			addInitializer( new Lifetime( 1, 1.1 ) ); 
			addInitializer( new Velocity( new LineZone(new Point(-60,-300), new Point(60,-350)) ) );
			addInitializer( new Position( new DiscZone(new Point(0,0),30,0) ) );
			
			addAction( new Age( Quadratic.easeOut ) );
			addAction( new Move() );
			addAction( new RandomDrift( 300, 20 ) );
			addAction( new Accelerate(0,900) );
		}
	}
}

