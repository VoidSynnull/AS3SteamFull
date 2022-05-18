package game.scenes.time.shared.emitters
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.SineCounter;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.RadialDot;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.ScaleAllInit;
	import org.flintparticles.twoD.zones.DiscZone;
	
	
	public class FlickeringLight extends Emitter2D
	{	
		/**
		 * creates flickering glow effect
		 */
		public function init(size:Number):void
		{
			super.counter = new SineCounter(2,3,1);
			addInitializer( new Lifetime( 1, 1 ) );
			addInitializer(new AlphaInit(0.2,0.25));
			addInitializer(new ScaleAllInit(0.8,1.0));
			addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 0.8 ) ) );
			addInitializer( new ImageClass( RadialDot, [size,0xD8D89F], true) );
			
			addAction( new Age( Quadratic.easeInOut ) );
			addAction( new Move( ) );
			addAction( new LinearDrag( 1 ) );
			addAction( new RotateToDirection() );
		}
		
		public function set rate(rate:int):void
		{
			Steady(super.counter).rate = rate;
		}
	}
}