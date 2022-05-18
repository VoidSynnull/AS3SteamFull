package game.particles.emitter.specialAbility 
{
	import flash.geom.Point;

	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.initializers.ExternalImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	
	
	
	public class Hearts extends Emitter2D
	{
		
		private var sAssetPath : String = "";
		
		public function Hearts(sPath:String) 
		{
			sAssetPath = sPath;
		}
		
		
		public function init():void
		{
			addInitializer( new ExternalImage( sAssetPath ) );
			super.counter = new Steady( 2 );
			
			addInitializer( new Lifetime( 2, 4 ) );
			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 20, 10, -Math.PI, 0 ) ) );
			addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 5 ) ) );
			
			addAction( new Age( ) );
			addAction( new Move( ) );
			addAction( new LinearDrag( 1 ) );
			addAction( new Accelerate( 0, -50 ) );
			addAction( new ScaleImage( 0.2, 0.6 ) );
			addAction( new Fade(1, 0) );
		}
		
		
		public function set rate(rate:int):void
		{
			Steady(super.counter).rate = rate;
		}
	}
}



