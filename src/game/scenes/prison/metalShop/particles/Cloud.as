package game.scenes.prison.metalShop.particles
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.Rotate;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.RotateVelocity;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Cloud extends Emitter2D
	{
		public function Cloud()
		{
			super();
		}
		
		public function init(size:Number = 16, rate:Number = 20, color:uint = 0xffffff, area:Rectangle = null):void
		{
			super.counter = new Steady( rate );
			
			addInitializer( new ImageClass( Blob, [size, color], true ) );
			addInitializer( new AlphaInit( .6, .7 ));
			addInitializer( new Lifetime( 1.0, 2.5 ) ); 
			addInitializer( new Velocity( new LineZone( new Point( -25, -25), new Point( -25, -25) ) ) );
			if(area){
				addInitializer( new Position( new RectangleZone(area.left,area.top,area.right,area.bottom)));
			}
			addInitializer( new RotateVelocity(1,2));
			
			addAction( new Age( Quadratic.easeOut ) );
			addAction( new Move() );
			addAction( new RandomDrift( 50, 50 ) );
			addAction( new ScaleImage( 0.8, 2.0 ) );
			addAction( new Rotate() );
			addAction( new Fade(.7, 0));
		}
	}
}