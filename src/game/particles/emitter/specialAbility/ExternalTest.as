package game.particles.emitter.specialAbility 
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ColorChange;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.initializers.ExternalImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	
	
	public class ExternalTest extends Emitter2D
	{	
		private var sAssetPath : String = "assets/particles/tear.swf";
		
		public function ExternalTest(sPath:String="assets/particles/tear.swf") 
		{	
			sAssetPath = sPath;
		}
		
		public function init():void
		{
			super.counter = new Steady( 80 );
			addInitializer( new ExternalImage( sAssetPath, true) );
			addInitializer( new Lifetime( 1, 2 ) );
			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 20, 10, -Math.PI, 0 ) ) );
			addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 7 ) ) );
			
			
			addAction( new Age( ) );
			addAction( new Move( ) );
			addAction( new LinearDrag( 1 ) );
			addAction( new Accelerate( 0, -40 ) );
			addAction( new ColorChange( 0xFFFFCC00, 0x00CC0000 ) );
			addAction( new ScaleImage( 1, 0.1 ) );
			addAction( new RotateToDirection() );
		}
		
		public function set rate(rate:int):void
		{
			Steady(super.counter).rate = rate;
		}
	}
	

}