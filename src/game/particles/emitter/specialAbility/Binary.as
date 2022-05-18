package game.particles.emitter.specialAbility
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import engine.ShellApi;
	
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.counters.TimePeriod;
	import org.flintparticles.common.displayObjects.Droplet;
	import org.flintparticles.common.initializers.CollisionRadiusInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Collide;
	import org.flintparticles.twoD.actions.CollisionZone;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.RotationAbsolute;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Binary extends Emitter2D
	{
		private var _box:Rectangle;
		
		public function init(box:Rectangle):void
		{
			_box = box;
			super.counter = new TimePeriod(30,5);
			addInitializer(new ImageClass(Droplet, [1.5, 0xC8FAFF], true));
			addInitializer( new CollisionRadiusInit( 12 ) );
			addInitializer(new Position(new RectangleZone(box.left, box.top, box.right, box.top)));
			addInitializer(new Velocity(new LineZone(new Point(-10, 1000), new Point(10, 2000))));
			addInitializer(new RotationAbsolute(1.5, 1.5));
			addSteadyCounter(5);
			addRandomDrift(0,0);
			
			addAction(new Move());
		}
		
		public function addCounter(timePeriod:TimePeriod):void
		{
			super.counter = timePeriod;
		}
		
		public function addSteadyCounter(rate:Number):void
		{
			super.counter = new Steady( rate );
		}
		
		public function addPins(shellApi:ShellApi):void
		{
			// no pins for this emitter
		}
		
		public function addRandomDrift(x:Number, y:Number):void
		{
			addAction(new RandomDrift(x, y));
		}
		
		public function addCollision():void
		{
			addAction( new Collide() );
		}
		
		public function addDeathZone():void
		{
			addAction(new DeathZone(new RectangleZone(_box.left - _box.width, _box.top - _box.height, _box.right * 2, _box.bottom * 2), true));
		}
	}
}
