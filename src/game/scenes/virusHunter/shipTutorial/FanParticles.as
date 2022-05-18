package game.scenes.virusHunter.shipTutorial
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ColorInit;
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
	
	public class FanParticles extends Emitter2D
	{
		public function FanParticles() 
		{
			
		}
		
		public function init():void
		{
			counter = new Steady(20);
			
			addInitializer( new ImageClass( Blob, [1.8], true ) );
			addInitializer( new Position( new LineZone( new Point( 0, -100 ), new Point( 0, 100 ) ) ) );
			addInitializer( new Velocity( new LineZone( new Point( 0, -50 ), new Point( 0, 50 ) ) ) );
			addInitializer( new ScaleImageInit( .5, 2) );
			//addInitializer( new ColorInit(0xFFffffff, 0x336f6f6f) );
			addInitializer( new ColorInit(0xFF861a16, 0x33ff0000) );
			addInitializer( new Lifetime( 2.8 ) );
			
			addAction( new Age() );
			addAction( new Move() );
			addAction(new Fade());
			//addAction( new DeathZone( new RectangleZone( bounds.x, bounds.y, bounds.width, bounds.height ), true ) );
			addAction( new RandomDrift( 100, 100 ) );
			addAction( new Accelerate(-200, -32) );
		}
	}
}