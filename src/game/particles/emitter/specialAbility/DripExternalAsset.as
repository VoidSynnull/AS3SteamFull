package game.particles.emitter.specialAbility 
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.zones.LineZone;
	
	// used for dripping zombie mouth card 3233
	public class DripExternalAsset extends Emitter2D
	{
		private var _assetPath : String = "";
		
		public function init(dir:int = 0):void
		{
			super.counter = new Steady( 1.5 );
			
			addInitializer( new Lifetime( 0.7 ) );
			addInitializer( new Position( new LineZone( new Point(0, 0), new Point(0, 20) ) ) );
			addInitializer( new ScaleImageInit( 0.5, 1 ) );
			
			addAction( new Age( ) );
			addAction( new Move( ) );
			addAction( new Accelerate( 0, 200 ) );
			addAction( new LinearDrag( 1 ) );
		}
		
		public function setRate (rate:Number):void
		{
			super.counter = new Steady( rate );
		}
		
		public function set rate(rate:int):void
		{
			Steady(super.counter).rate = rate;
		}
	}
}
