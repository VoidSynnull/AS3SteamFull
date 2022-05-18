package game.particles.emitter
{
	import flash.geom.Point;
	
	import fl.motion.easing.Quadratic;
	
	import game.creators.entity.EmitterCreator;
	import game.util.EntityUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class GreenSmoke extends Emitter2D
	{
		public function GreenSmoke()
		{
			super();
		}
		public function init():void
		{
			this.counter = new Random( 25, 40 );
			this.addInitializer( new ImageClass( Dot, [ 8 ], true ));
			this.addInitializer( new ColorInit( 0x6FC970, 0x418A28 ));	// initialize from a color range
			this.addInitializer( new AlphaInit( .8, 1 ));				// initialize from a alpha range
			this.addInitializer( new Position( new RectangleZone( -80, -25, 80, 115 )));
			this.addInitializer( new Velocity( new LineZone( new Point( 0, -120 ), new Point( 0, -80 ))));
			this.addInitializer( new Lifetime( .5, 1.5 ));
			this.addAction( new Age( Quadratic.easeIn ));
			this.addAction( new Move());
			this.addAction( new Accelerate( 0, -80 ));
			this.addAction( new RandomDrift( 15, 15 ));				// add a random drift
			this.addAction( new Fade( 1, 0 ));								// cause alpha to decrease with age
			this.addAction( new ScaleImage( 1, .4 ));					// cause scale to decrease with age		
		}
	}
}