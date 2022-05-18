package game.particles.emitter.specialAbility 
{
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.TimePeriod;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ChooseInitializer;
	import org.flintparticles.common.initializers.ImageClass;
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
	
	
	public class ShootSpitballs extends Emitter2D
	{	
		public function ShootSpitballs() 
		{	
		}
		
		public function init(dir:int):void
		{
			super.counter = new TimePeriod(5,1);
			addInitializer( new Lifetime( 2, 2 ) );
			var angle:Number = 0;
			if (dir == -1)
				angle = Math.PI;
			
			//angle *= -1;
			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 600, 400, angle,angle) ) );
			addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 4 ) ) );
			addInitializer( new ImageClass( Blob, [15]) );
			addInitializer( new AlphaInit(.8,.8));
			addInitializer( new ChooseInitializer([new ImageClass(Blob, [3], true)]));
			
			addAction( new Age( ) );
			addAction( new Move( ) );
			addAction( new LinearDrag( 1 ) );
			addAction( new Accelerate( dir * 100, 0 ) );
			
			var myTimer:Timer = new Timer(1000,0);
			myTimer.addEventListener(TimerEvent.TIMER, timerListener);
		
			myTimer.start();
		}
		private function timerListener (e:TimerEvent):void
		{
			//this.pause();
		}
	}
}


