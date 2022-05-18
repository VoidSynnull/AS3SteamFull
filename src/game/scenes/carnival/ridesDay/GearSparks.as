package game.scenes.carnival.ridesDay
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.TargetColor;
	import org.flintparticles.common.actions.TargetScale;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Dot;
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
	import org.flintparticles.twoD.zones.PointZone;
	
	public class GearSparks extends Emitter2D
	{	
		public function GearSparks() {
			
		}
		
		public function init():void
		{
			counter = new Steady(50);
			
			addInitializer( new ImageClass( Dot, [1], true ) );
			addInitializer( new Position( new PointZone( new Point( 0, 0 ) ) ) );
			addInitializer( new Velocity( new PointZone( new Point( -120, -120 ) ) ) );
			addInitializer( new ScaleImageInit( .5, 2) );
			addInitializer( new ColorInit(0xFFffff66, 0xFFffcc00) );
			addInitializer( new Lifetime( 1 ) );
			
			addAction( new Age() );
			addAction( new Move() );
			addAction( new RandomDrift( 1150, 1125 ) );
			addAction( new Accelerate(0, 0) );
			addAction( new TargetColor(0xFFff0000, 0.5));
			addAction( new TargetScale(.1, 0.5));
		}
	}
}