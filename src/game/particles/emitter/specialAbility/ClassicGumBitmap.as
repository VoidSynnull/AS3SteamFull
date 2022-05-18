package game.particles.emitter.specialAbility 
{
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import game.util.BitmapUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ColorChange;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.RadialDot;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ExternalImage;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.AntiGravity;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.actions.ScaleAll;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	
	
	public class ClassicGumBitmap extends Emitter2D
	{	
		private var sAssetPath : String = "assets/particles/tear.swf";
		private var uBlastCount : uint = 6;
		private var _assetMC:MovieClip;
		private var _shouldBitmap:Boolean = false;
		
		public function ClassicGumBitmap(sPath:String="assets/particles/classicgum.swf", nBlastCount:uint=6) 
		{	
			sAssetPath = sPath;
			uBlastCount = nBlastCount;
			_shouldBitmap = false;
		}
		public function setAssetMC(assetMC:MovieClip):void
		{
			_assetMC = assetMC;
		}
		public function setBitmap(shouldBitmap:Boolean):void
		{
			_shouldBitmap = shouldBitmap;
		}
		public function init():void
		{
			super.counter = new Blast( uBlastCount );
				var bitmapData:BitmapData = BitmapUtils.createBitmapData(_assetMC);
				addInitializer( new BitmapImage(bitmapData) );
				trace("========BITMAPPING===");

			
			addInitializer( new Lifetime( .5, 1 ) );;
			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 75, 65, -Math.PI, 0 ) ) );
			addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 12 ) ) );
			
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


