package game.scenes.ftue.shared.particles
{
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import engine.components.Spatial;
	
	import game.data.TimedEvent;
	import game.util.BitmapUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.GravityWell;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.TargetVelocity;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	
	public class SmokeParticles extends Emitter2D 
	{
		public function init(clip:DisplayObjectContainer ):void
		{
			
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(clip);
			
			if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_LOW){
				super.addInitializer( new BitmapImage(bitmapData, true, 20) );
			} else {
				_imageClass = new ImageClass(Blob, [25, 0x000000], true);
				super.addInitializer( _imageClass );
			}
			
			super.addInitializer( new Position( new EllipseZone( new Point(1, 1), 40, 40) ));
			super.addInitializer( new Velocity( new EllipseZone( new Point(0,0), 20, 20 ) ));
			
			_lifetime = new Lifetime( 2, 0.5 );
			
			super.addInitializer( _lifetime );
			
			super.addAction( new Move() );
			super.addAction( new Age() );
			super.addAction( new ScaleImage( 1, 0.1) );
			super.addAction( new Accelerate( -400, 0) );
			super.addAction( new TargetVelocity(-100));
		}
		
		public function stream():void{
			super.counter = new Steady(40);
		}
		
		public function stopStream():void{
			super.counter = new Steady(0);
		}
		
		
		public var _imageClass:ImageClass;
		private var _colorInit:ColorInit;
		private var _origSpatial:Spatial;
		private var _gravityWell:GravityWell;
		private var _lifetime:Lifetime;

		
	}
}