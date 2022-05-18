package game.scenes.carrot.smelter
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.TimePeriod;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	

	public class Sparks extends Emitter2D
	{		
		public function init():void
		{
		    addInitializer( new ImageClass( Dot, [1], true ) );
		    addInitializer( new Position( new LineZone( new Point( -15, 0 ), new Point( 15, 0 ) ) ) );
		    addInitializer( new Velocity( new LineZone( new Point( -8, -8 ), new Point( 8, 0 ) ) ) );
		    addInitializer( new ScaleImageInit( .5, 2) );
			addInitializer( new ColorInit(0xFFffff66, 0xFFffcc00) );
			addInitializer( new Lifetime( 1.2 ) ); 
			
			addAction( new Age() );
		    addAction( new Move() );
		    addAction( new RandomDrift( 150, 25 ) );
			addAction( new Accelerate(0, 200) );
		}
	}
}