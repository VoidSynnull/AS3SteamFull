package game.particles.emitter.specialAbility 
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ColorChange;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.RadialDot;
	import org.flintparticles.common.initializers.ExternalImage;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	
	
	public class ExternalBlast extends Emitter2D
	{	
		private var sAssetPath : String = "assets/particles/tear.swf";
		private var uBlastCount : uint = 20;
		
		public function ExternalBlast(sPath:String="assets/particles/tear.swf", nBlastCount:uint=20) 
		{	
			sAssetPath = sPath;
			uBlastCount = nBlastCount;
		}
		
		public function init():void
		{
			super.counter = new Blast( uBlastCount );
			
			addInitializer( new ExternalImage( sAssetPath, true) );
			addInitializer( new Lifetime( 12, 14 ) );;
			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 75, 10, -Math.PI, 0 ) ) );
			addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 12 ) ) );
			addInitializer( new ScaleImageInit( 0.1, 0.25) );
			
			addAction( new Age( ) );
			addAction( new Move( ) );
			addAction( new RotateToDirection() );
			addAction( new Accelerate( 0, 220 ) );
			addAction( new LinearDrag( 0.3 ) );
		}
		
		public function set rate(rate:int):void
		{
			Steady(super.counter).rate = rate;
		}
	}
	

}