package game.scenes.time.shared.emitters
{
	import flash.geom.Point;
	
	import fl.motion.easing.Quadratic;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class SmokeStream extends Emitter2D
	{
		public function SmokeStream()
		{
		}
		
		// Steady stream of smoke for a second then pause
		// Pause for 2 seconds then stream smoke again
		public override function update(time:Number):void
		{
			if(_stopped)
			{
				_stopTime += time;
				if(_stopTime >= 2)
				{
					_stopped = false;
					_startTime = 0;
					super.counter.resume();
				}
			}
			else
			{
				_startTime += time;
				
				if(_startTime >= 1)
				{
					_stopTime = 0;
					_stopped = true;
					super.counter.stop();
				}
			}
			
			super.update(time);
		}
		
		public function init(box:RectangleZone, count:Number = 10, size:Number = 8):void
		{
			super.counter = new Steady(count);
			
			addInitializer(new ImageClass(Blob, [size, 0xFFFFFF], true));
			addInitializer(new AlphaInit(.4));
			addInitializer(new ScaleImageInit(.3, 1));
			addInitializer(new Velocity(new LineZone(new Point(0, -40), new Point(0, -40))));
			addInitializer(new Lifetime(4.5, 5));
			addInitializer(new Position(new LineZone(new Point(box.left, box.top), new Point(box.right, box.top))));
			
			addAction(new Move());
			addAction(new Age(Quadratic.easeOut));
			addAction(new Fade(.4, 0));
			addAction(new Accelerate(-50, 0));
			addAction(new RandomDrift(0, -20));
		}
		
		private var _stopTime:Number = 0;
		private var _startTime:Number = 0;
		private var _stopped:Boolean = false;
	}
}