package game.particles.emitter.specialAbility 
{
	import flash.geom.Point;
	
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ColorInit;
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
	
	
	public class DustDrift extends Emitter2D
	{	
		private var sceneW : Number=0;
		private var sceneH : Number=0;
		
		public function DustDrift(xW:Number, yH:Number) 
		{	
			sceneW = xW;
			sceneH = yH;
		}
		
		public function init():void
		{
			
			var startLineZone : LineZone = new LineZone( new Point( -500, 0 ), new Point( sceneW, 0 ) );
			var startVelocity : Point = new Point( 40, 145 );
			var allowedZone : RectangleZone = new RectangleZone( -500, -50, sceneW, sceneH );
			
			counter = new Steady( 1200 );
			
			
			this.addInitializer( new AlphaInit( .6, 1 ));
			this.addInitializer( new ImageClass( Dot, [8], true ) );
			this.addInitializer( new Position( startLineZone ) );
			this.addInitializer( new Velocity( new PointZone( startVelocity ) ) );
			this.addInitializer( new ScaleImageInit( .1, .3) );
			this.addInitializer( new ColorInit(0xFF0000, 0xFF0000));
			//addInitializer( new Lifetime( 3 ) );
			
			//addAction( new Age() );
			addAction( new Move() );
			addAction( new DeathZone( allowedZone, true ) );
			addAction( new RandomDrift( 200, 0 ) );
			addAction( new RotateToDirection() );
			addAction( new Accelerate(0, 0) );
			runAhead( 120 );
		}
		
		public function set rate(rate:int):void
		{
			Steady(super.counter).rate = rate;
		}
		
		
		private function randomRange(minNum:Number, maxNum:Number):Number 
		{
			return (Math.floor(Math.random() * (maxNum - minNum + 1)) + minNum);
		}
		
		
	}
	
	
}


