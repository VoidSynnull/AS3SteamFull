package game.particles.emitter.specialAbility
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.TimePeriod;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Friction;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.ScaleAll;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.LineZone;
	
	
	
	public class FirefighterExtinguisher extends Emitter2D
	{
		public function FirefighterExtinguisher()
		{
		}
		
		public function init(dirNum:Number = 1):void
		{
			super.counter = new TimePeriod(30,.5);
			addInitializer( new ScaleImageInit(.8, 1.2));
			addInitializer( new Lifetime( .2, .5 ) );
			addInitializer( new Velocity( new LineZone(new Point(dirNum*200, -40), new Point(dirNum*200, -50)) ));
			addInitializer( new Position( new DiscZone( new Point( dirNum*15, -8 ), 4 ) ) );
			addInitializer( new ImageClass( Dot, [2.2, 0xFFFFFF], true) );
			addInitializer( new AlphaInit(.4, .9));
			
			addAction( new Age( ) );
			addAction( new Move() );
			addAction( new Accelerate( 20, -80) );
			addAction( new ScaleAll(.5, 1.7));
			addAction(new Friction(2));
		}
	}
}