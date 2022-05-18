package game.scenes.arab1.shared.particles
{
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import engine.components.Spatial;
	import engine.group.Group;
	
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
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	import org.osflash.signals.Signal;
	
	public class SmokeParticles extends Emitter2D 
	{
		public function init($group:Group, $clip:DisplayObjectContainer, $life:Number = 2.0, $width:Number = 45, $height:Number = 80, $particleScale:Number = 1.0, $gravity:Number = -200, $velocity:Number = 40.0, $fromLamp:Boolean = false, $lowQColor:uint = 0x000000, $allowLowQBitmap:Boolean = true ):void
		{
			_group = $group;
			
			if(PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_LOW || !$allowLowQBitmap)
			{
				var bitmapData:BitmapData = BitmapUtils.createBitmapData($clip);
				
				super.addInitializer( new BitmapImage(bitmapData, true, 20) );
			} else {
				_imageClass = new ImageClass(Blob, [25, $lowQColor], true);
				super.addInitializer( _imageClass );
			}
			
			super.addInitializer( new Position( new EllipseZone( new Point(-25*$particleScale,-25*$particleScale), $width, $height ) ));
			super.addInitializer( new Velocity( new EllipseZone( new Point(0,0), $velocity, $velocity ) ));
			
			_lifetime = new Lifetime( $life, 0.5 );
			
			super.addInitializer( _lifetime );
			
			super.addAction( new Move() );
			//super.addAction( new Fade() );
			super.addAction( new Age() );
			if(!$fromLamp){
				super.addAction( new ScaleImage( 1.4*$particleScale, 0.1) );
			} else {
				super.addAction( new ScaleImage( 0.1, 1.4*$particleScale) );
			}
			super.addAction( new Accelerate( 0, $gravity) );
		}
		
		public function puff():void{
			// fast explosive puff
			_lifetime = new Lifetime( 2, 0.5 );
			super.counter = new Steady(230);			
			SceneUtil.addTimedEvent(_group, new TimedEvent(0.1, 1, stopPuff));
		}
		
		public function screen():void{
			// lingering screen of smoke
			_lifetime = new Lifetime( 4, 1 );
			super.counter = new Steady(40);
			SceneUtil.addTimedEvent(_group, new TimedEvent(3, 1, stopPuff));
		}
		
		public function stream($howLong:Number = 4.0, $howMuch:int = 15):void{
			// constant stream of smoke
			_lifetime = new Lifetime( 2, 0.5 )
			super.counter = new Steady($howMuch);
			SceneUtil.addTimedEvent(_group, new TimedEvent($howLong, 1, stopPuff));
		}
		
		private function stopPuff():void{
			super.counter = new Steady(0);
			endParticle.dispatch();
		}
		
		public var _imageClass:ImageClass;
		private var _colorInit:ColorInit;
		private var _origSpatial:Spatial;
		private var _gravityWell:GravityWell;
		private var _lifetime:Lifetime;
		
		private var _group:Group;
		
		public var endParticle:Signal = new Signal();
		
	}
}