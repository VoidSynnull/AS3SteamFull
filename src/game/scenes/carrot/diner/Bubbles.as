package game.scenes.carrot.diner
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Ring;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class Bubbles extends Emitter2D
	{		
		public function init(lifetime:Number):void
		{
			counter = new Steady(10);
			
			addInitializer( new ImageClass( Ring, [1, 2], true ) );
			addInitializer( new Position( new LineZone( new Point( -45, 0 ), new Point( 45, 0 ) ) ) );
			addInitializer( new Velocity( new PointZone( new Point( 0, -50 ) ) ) );
			addInitializer( new ScaleImageInit(0.5, 2) );
			addInitializer( new ColorInit(0x66FFFFFF, 0x66FFFFFF) );
			addInitializer( new Lifetime( lifetime ) );
			
			addAction( new Age() );
			addAction( new Move() );
			addAction( new Accelerate(0, -50));
		}
	}
}