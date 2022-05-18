package game.particles.emitter.specialAbility 
{
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.net.URLRequest;
	
	import game.util.BitmapUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class DropExternalBitmap extends Emitter2D
	{
		
		private var sAssetPath : String = "";
		
		public function DropExternalBitmap(sPath:String) 
		{
			trace(sPath);
			sAssetPath = sPath;
		}
		
		private function swfReady(e:Event):void
		{
			e.currentTarget.removeEventListener(Event.COMPLETE, swfReady);
			
			var displayMC : MovieClip = new MovieClip();
			displayMC.addChild(e.currentTarget.content);
			
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(displayMC);
			
			addInitializer( new BitmapImage(bitmapData) );
			
			super.counter = new Steady( 1 );
			
			addInitializer( new Lifetime( 2, 4 ) );
			addInitializer( new Position( new LineZone( new Point(0, 0), new Point(0, 20) ) ) );
			addInitializer( new ScaleImageInit( 0.2, 0.6 ) );
			
			addAction( new Age( ) );
			addAction( new Move( ) );
			addAction( new LinearDrag( 1 ) );
			addAction( new Accelerate( 0, 50 ) );
		}
		
		public function init():void
		{
			if(sAssetPath != ""){
					var ldr : Loader = new Loader();
					ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, swfReady);
					ldr.load(new URLRequest(sAssetPath));
				}
				
		}
		
		
		public function set rate(rate:int):void
		{
			Steady(super.counter).rate = rate;
		}
	}
}



