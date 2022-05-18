package game.scenes.carrot.diner
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Ellipse;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class Spout extends Emitter2D
	{		
		public function init(color:uint):void
		{
			counter = new Steady(12);
			
			addInitializer( new ImageClass( Ellipse, [2, 4], true ) );
			addInitializer( new Position( new LineZone( new Point( -7, -4 ), new Point( -5, -4 ) ) ) );
			addInitializer( new Velocity( new LineZone( new Point( 0, 300 ), new Point( 0, 300 ) ) ) );
			addInitializer( new ScaleImageInit(8, 6) );
			addInitializer( new ColorInit(color, color) );
			addInitializer( new Lifetime( 0.45 ) );
			
			addAction( new Age() );
			addAction( new Move() );
		}
	}
}