package game.scenes.virusHunter.pdcLab.particles
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Dot;
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

	/**
	 * ...
	 * @author Bard McKinley
	 */
	public class ParticleExample1 extends Emitter2D
	{
		public function init():void
		{
			//super.counter = new Steady(70);
	
			super.addInitializer( new ImageClass( Dot, [2], true ) );
			super.addInitializer( new ColorInit(0xDEFFC6, 0xffffff) );
			super.addInitializer( new Position( new LineZone( new Point( -113, 0 ), new Point(113, 0)) ));
			super.addInitializer( new Velocity( new LineZone( new Point( -40, 200 ), new Point(40, 200)) ) );
			super.addInitializer( new Lifetime( 2, 0.5 ) );

			super.addAction( new Age() );
			super.addAction( new Move() );
			super.addAction( new Accelerate(0, 200) );
			super.addAction( new RandomDrift( 30, 30 ) );
			super.addAction( new Fade() );		
			super.addAction( new ScaleImage( 1, 30) );	
		}
		
		public function startGas():void{
			super.counter = new Steady(70);
		}
		
		public function stopGas():void{
			super.counter = new Steady(0);
		}
	}

}