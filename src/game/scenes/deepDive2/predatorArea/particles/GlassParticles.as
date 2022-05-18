package game.scenes.deepDive2.predatorArea.particles
{
	import flash.display.BitmapData;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.Rotate;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.RotateVelocity;
	import org.flintparticles.twoD.initializers.Rotation;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;

	public class GlassParticles extends Emitter2D
	{
		public function init($bitmapData:BitmapData, speedX:Number = 150, speedY:Number = 180, accX:Number = 0, accY:Number = 100):void
		{
			//super.addInitializer( new ImageClass( Dot, [2], true ) );
			//super.addInitializer( new ColorInit(0xDEFFC6, 0xffffff) );
			super.addInitializer( new BitmapImage($bitmapData) );
			super.addInitializer( new Rotation(-90,90) );
			super.addInitializer( new RotateVelocity(-4,4) );
			super.addInitializer( new Position( new EllipseZone( new Point(0,0), 10, 10 ) ));
			super.addInitializer( new Velocity( new EllipseZone( new Point(0,0), speedX, speedY ) ));
			super.addInitializer( new Lifetime( 6, 0.5 ) );
			super.addInitializer( new ScaleImageInit(0.4,1) );
			
			super.addAction( new Age() );
			super.addAction( new Move() );
			super.addAction( new Accelerate(accX, accY) );
			super.addAction( new RandomDrift( 30, 30 ) );
			super.addAction( new Fade() );			
			super.addAction( new Rotate() );			
		}

		public function spark($amount:Number = 50, time:Number = 100):void{
			super.counter = new Steady($amount);
			timer = new Timer(time, 1);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE, sparkOff);
			timer.start();
		}
		
		public function sparkOff($event:TimerEvent):void{
			timer.removeEventListener(TimerEvent.TIMER_COMPLETE, sparkOff);
			super.counter = new Steady(0);
		}
		
		private var timer:Timer;
	}

}