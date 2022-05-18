package game.particles.emitter.specialAbility
{
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Ring;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Bubbles extends Emitter2D
	{
		public function Bubbles()
		{
			super();
		}
		
		public function init(dir:int = 0):void
		{
			counter = new Random(5, 10);
			addInitializer( new ImageClass( Ring,[5,6,0xB1E0F0],true) );
			addInitializer( new Position(new RectangleZone(-5,-5,5,5)));
			addInitializer( new ScaleImageInit( .5, 1.5) );
			addInitializer( new Lifetime( 1, 1.5 ) );
			
			addAction( new Age() );
			addAction( new Move() );
			addAction( new RandomDrift( 25, 25 ) );
			addAction( new Accelerate(0, -50) );
		}
	}
}