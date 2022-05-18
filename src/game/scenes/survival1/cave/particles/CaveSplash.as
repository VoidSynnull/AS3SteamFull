package game.scenes.survival1.cave.particles
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	import game.util.BitmapUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ColorsInit;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class CaveSplash extends Emitter2D
	{
		private var deathZoneRadius:int = 600;
		
		public function CaveSplash( position:Point, color1:Number = 0x6696E1, color2:Number = 0x6696AF )
		{
			this.counter = new Blast(3);
			
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(new Dot(2));
			
			// when using a BitmapRender you use SharedImage or SharedImages, since each particle is being draw to bitmap it only needs to be rendered once.
			this.addInitializer( new BitmapImage(bitmapData) );
			this.addInitializer(new Position(new PointZone()));
			this.addInitializer(new Velocity(new RectangleZone(-60, -160, 60, -100)));
			this.addInitializer(new ColorsInit([color1, color2]));
			this.addInitializer(new AlphaInit());
			this.addInitializer(new Lifetime(4));

			this.addAction(new DeathZone( new RectangleZone( position.x - deathZoneRadius, position.y, position.x + deathZoneRadius, position.y + 20 ), false ) );
			this.addAction(new Move());
			this.addAction(new Age());
			this.addAction(new Accelerate(0, 400));
		}
	}
}