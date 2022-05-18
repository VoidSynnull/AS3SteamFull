package game.particles.emitter.specialAbility 
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.AntiGravity;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.ScaleAll;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	
	
	public class ClassicGum extends Emitter2D
	{	
		private var sAssetPath : String = "assets/particles/tear.swf";
		private var uBlastCount : uint = 6;
		
		public function ClassicGum(sPath:String="assets/particles/classicgum.swf", nBlastCount:uint=6) 
		{	
			sAssetPath = sPath;
			uBlastCount = nBlastCount;
		}
		
		public function init():void
		{
			super.counter = new Blast( uBlastCount );
			
			//addInitializer( new ExternalImage( sAssetPath, true) );
			addInitializer( new Lifetime( .5, 1 ) );;
			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 75, 65, -Math.PI, 0 ) ) );
			addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 12 ) ) );
			addInitializer( new ImageClass( Blob, [7, 0xFE8181], true) );
			
			addAction( new Age( ) );
			addAction( new Move( ) );
			addAction(new AntiGravity(30) );
			addAction( new Accelerate( Math.random()*400 - 200, Math.random()*400 - 200 ) );
			addAction( new Fade(1, 0));
			addAction( new ScaleAll(1.4, 0));
		}
		
		public function set rate(rate:int):void
		{
			Steady(super.counter).rate = rate;
		}
	}
	
	
}