package game.particles.emitter.specialAbility 
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.initializers.ExternalImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class DropExternalAsset extends Emitter2D
	{
		
		private var _assetPath : String = "";
		private var _move:Boolean = false; // changed default to false
		
		public function init(dir:int = 0):void
		{
			super.counter = new Steady( 1 );
			
			addInitializer( new Lifetime( 2, 4 ) );
			addInitializer( new Position( new LineZone( new Point(0, 0), new Point(0, 20) ) ) );
			addInitializer( new ScaleImageInit( 0.2, 0.6 ) );
			
			addAction( new Age( ) );
			
			if(_move)
			{
				addAction( new Move( ) );
				addAction( new Accelerate( 0, 50 ) );
			}
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
