package game.particles.emitter.specialAbility
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.TimePeriod;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.LineZone;
	
	
	// dirNum comes in as 1 or -1
	public class ClownWater extends Emitter2D
	{
		
		public function ClownWater()
		{
		}
		
		public function init(dirNum:Number):void
		{
			super.counter = new TimePeriod(20,.5);
			addInitializer( new Lifetime( .2, .5 ) );
			addInitializer( new Velocity( new LineZone(new Point(dirNum*200, -40), new Point(dirNum*200, -50)) ));
			addInitializer( new Position( new DiscZone( new Point( dirNum*15, -22 ), 7 ) ) );
			addInitializer( new ImageClass( Dot, [2.2, 0x33C2FF], true) );
			addInitializer( new AlphaInit(.4, .8));
			
			addAction( new Age( ) );
			addAction( new Move() );
			addAction( new Accelerate( 0, 800) );
		}
		
		
	}
}