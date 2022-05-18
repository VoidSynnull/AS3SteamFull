package game.scenes.mocktropica.chasm.particles
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.SharedImage;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.particles.Particle2D;
	import org.flintparticles.twoD.particles.Particle2DUtils;
	import org.flintparticles.twoD.zones.EllipseZone;

	public class NarfParticles extends Emitter2D
	{
		public function init($texture:BitmapData):void
		{

			//super.addInitializer( new ImageClass( Dot, [2], true ) );
			super.addInitializer( new SharedImage(new Bitmap($texture)));
			super.addInitializer( new ColorInit(0xDEFFC6, 0xffffff) );
			super.addInitializer( new Position( new EllipseZone( new Point(0,0), 10, 10 ) ));
			super.addInitializer( new Velocity( new EllipseZone( new Point(0,0), 400, 200 ) ));
			super.addInitializer( new Lifetime( 4, 0.5 ) );
			
			//super.addParticle(_narfParticle, true);
			
			super.addAction( new Age() );
			super.addAction( new Move() );
			super.addAction( new Accelerate(0, 200) );
			super.addAction( new RandomDrift( 30, 30 ) );
			super.addAction( new Fade() );
			//super.addAction( new ScaleImage( 1, 0.1) );	
		}
		
		public function spark($amount:Number = 50):void{
			super.counter = new Steady($amount);
			/*timer = new Timer(100, 1);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE, sparkOff);
			timer.start();*/
		}
		
		public function sparkOff($event:TimerEvent):void{
			timer.removeEventListener(TimerEvent.TIMER_COMPLETE, sparkOff);
			super.counter = new Steady(0);
		}
		
		private var timer:Timer;
		
		private var _narfParticle:Particle2D;
		private var _texture:BitmapData;
	}

}