package game.particles.emitter.specialAbility 
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.TimePeriod;
	import org.flintparticles.common.displayObjects.Line;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;

	
	
	
	public class SillyString extends Emitter2D
	{
		public function init(stringVel:Number ):void
		{
			super.counter = new TimePeriod(100, .6);
			addInitializer( new ImageClass( Line, [5, 0xC49F45], true) );	
			var stringDir:Number = 300 * stringVel;
			addInitializer(new Velocity(new LineZone(new Point(stringDir, 0), new Point(stringDir, 0))));
			addInitializer( new Lifetime( 0.5, 1 ) );

			addAction(new Age());
			addAction(new Move());
			addAction( new Accelerate( 0, 200 ) );
			addAction( new Fade( 1, 0 ) );
			addAction( new ScaleImage( 1, 0.5 ) );
		}
	}
}