package game.scenes.survival1.cave.particles
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import game.util.BitmapUtils;
	
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Droplet;
	import org.flintparticles.common.events.ParticleEvent;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ColorsInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	import org.osflash.signals.Signal;
	
	public class CaveDrip extends Emitter2D
	{
		public var index:int;
		public var deadParticle:Signal = new Signal(Emitter2D);
		
		public function CaveDrip( zone:Rectangle, rate:Number, index:int, color1:Number = 0x6696E1, color2:Number = 0x6696AF)
		{
			this.index = index;
			
			this.start();
			
			this.counter = new Random(0, rate);
			
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(new Droplet(4));
			
			// when using a BitmapRender you use SharedImage or SharedImages, since each particle is being draw to bitmap it only needs to be rendered once.
			this.addInitializer( new BitmapImage(bitmapData) );
			this.addInitializer(new Position(new PointZone(new Point(0, 0))));
			this.addInitializer(new Velocity(new PointZone(new Point(0, 0))));
			this.addInitializer(new ColorsInit([color1, color2]));
			this.addInitializer(new AlphaInit());
			this.addAction(new DeathZone(new RectangleZone( zone.x - 10, zone.y, zone.x + 10, zone.bottom), true));
			this.addAction(new Move());
			this.addAction(new RotateToDirection());
			this.addAction(new Accelerate(0, 300));
			
			this.addEventListener(ParticleEvent.PARTICLE_DEAD, this.onDeadParticle);
		}
		
		public function destroy():void
		{
			this.removeEventListener(ParticleEvent.PARTICLE_DEAD, this.onDeadParticle);
			
			this.deadParticle.removeAll();
			this.deadParticle = null;
		}
		
		private function onDeadParticle(event:ParticleEvent):void
		{
			this.deadParticle.dispatch(this);
		}
	}
}