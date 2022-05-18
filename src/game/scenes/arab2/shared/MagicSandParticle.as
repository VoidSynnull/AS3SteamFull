package game.scenes.arab2.shared
{
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.CollisionZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.SpeedLimit;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.BitmapDataZone;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class MagicSandParticle extends Emitter2D
	{
		public function init($collisionMap:BitmapData, $mapOffsetX:Number = 0, $mapOffsetY:Number = 0, $mapScale:Number = 1, $particleClip:DisplayObjectContainer = null):void
		{
			//var bitmapData:BitmapData = BitmapUtils.createBitmapData($particleClip);
			
			super.addInitializer(new ImageClass( Dot, [2] ));
			super.addInitializer( new Position( new LineZone(new Point(0,0), new Point(2860,0)) ));
			super.addInitializer( new Velocity( new DiscZone(new Point(0,0), 100) ));
			super.addInitializer(new Lifetime( 7, 0.5 ));
			
			super.addAction( new Move() );
			super.addAction( new CollisionZone( new BitmapDataZone($collisionMap, $mapOffsetX, $mapOffsetY, $mapScale), 0.3 ) );
			super.addAction( new Age() );
			super.addAction( new Accelerate( 0, 500 ) );
			super.addAction( new SpeedLimit( 500 ) );
			
			super.counter = new Steady(30);
		}
	}
}

