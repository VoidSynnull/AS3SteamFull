package game.scenes.carrot.vent
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class VentDust extends Emitter2D
	{
		public function VentDust() 
		{
			
		}
		
		public function init(bounds:Rectangle, radius:Number = 1, colorPrimary:uint = 0xFFffffff, colorSecondary:uint = 0x336f6f6f):void
		{
			counter = new Steady(15);
			
			addInitializer( new ImageClass( Dot, [radius], true ) );
			addInitializer( new Position( new LineZone( new Point( -35, 0 ), new Point( 35, 0 ) ) ) );
			addInitializer( new Velocity( new PointZone( new Point( 0, -50 ) ) ) );
			addInitializer( new ScaleImageInit( .5, 2) );
			addInitializer( new ColorInit(colorPrimary, colorSecondary) );
			//addInitializer( new Lifetime( 5.57 ) );
			
			//addAction( new Age() );
			addAction( new Move() );
			addAction( new DeathZone( new RectangleZone( bounds.x, bounds.y, bounds.width, bounds.height ), true ) );
			addAction( new RandomDrift( 100, 100 ) );
			addAction( new Accelerate(0, -200) );
		}
	}
}