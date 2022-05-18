package game.particles.emitter.specialAbility
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
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
	import org.flintparticles.twoD.initializers.Rotation;
	import org.flintparticles.twoD.initializers.RotationAbsolute;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	import engine.ShellApi;
	
	public class AssetRain extends Emitter2D
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
			addInitializer(new ScaleImageInit(.75, 1.25));
			addInitializer(new RotationAbsolute(1.5, 1.5));
			addInitializer(new Rotation(0,360));
			
			addAction(new Move());
			addAction(new RandomDrift(300, -25));
		}
		
		public function addPins(shellApi:ShellApi):void
		{
			for(var x:Number = 0; x < shellApi.viewportWidth; x += 20)
			{
				addAction( new CollisionZone( new PointZone(new Point( x, shellApi.viewportHeight-50 ) ), 0.5 )); 
			}
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


