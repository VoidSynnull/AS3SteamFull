package game.particles.emitter.specialAbility 
{
	import flash.geom.Point;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.RadialDot;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	
	public class Snow extends Emitter2D
	{	
		private var sceneW : Number=2400;
		private var sceneH : Number=1000;
		
		public function Snow(xW:Number=2400, yH:Number=1000) 
		{	
			sceneW = xW;
			sceneH = yH;
		}
		
		public function init():void
		{		
			var startLineZone : LineZone = new LineZone( new Point( 0, 0 ), new Point( sceneW, 0 ) );
			var startVelocity : Point = new Point( 0, 30 );
			var allowedZone : RectangleZone = new RectangleZone( -50, -50, sceneW, sceneH );
		
			counter = new Steady( 100 );

			addInitializer( new ImageClass( RadialDot, [3], true ) );
			addInitializer( new Position( startLineZone ) );
			addInitializer( new Velocity( new PointZone( startVelocity ) ) );
			addInitializer( new ScaleImageInit( .5, 1.5) );
			//addInitializer( new ColorInit(0xFFFFFF, 0xFFFFFF));
			//addInitializer( new Lifetime( 3 ) );
			
			//addAction( new Age() );
			addAction( new Move() );
			addAction( new DeathZone( allowedZone, true ) );
			addAction( new RandomDrift( 400, 200 ) );
			addAction( new RotateToDirection() );
			addAction( new Accelerate(0, 50) );
			runAhead( 120 );
		}
		
		public function set rate(rate:int):void
		{
			Steady(super.counter).rate = rate;
		}
		
		public function get rate():int
		{
			return Steady(super.counter).rate;
		}
	}
}