package game.scenes.mocktropica.megaFightingBots.particles
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

	public class DustParticles extends Emitter2D
	{
		public function init():void
		{
			super.addInitializer( new ImageClass( Dot, [2], true ) );
			super.addInitializer( new ColorInit(0xA68844, 0xC8C176) );
			super.addInitializer( new Position( new LineZone( new Point( -20, 0 ), new Point(20, 0)) ));
			super.addInitializer( new Velocity( new LineZone( new Point( -20, -5 ), new Point(20, -5)) ) );
			super.addInitializer( new Lifetime( 1.4, 0.5 ) );

			super.addAction( new Age() );
			super.addAction( new Move() );
			super.addAction( new Accelerate(0, -6) );
			super.addAction( new RandomDrift( 15, 5 ) );
			super.addAction( new Fade() );		
			super.addAction( new ScaleImage( 1, 5) );	
		}
		
		public function dustOn():void{
			super.counter = new Steady(30);
			state = 1;
		}
		
		public function dustOff():void{
			super.counter = new Steady(0);
			state = 0;
		}
		
		public function chargeDust():void{
			super.counter = new Steady(100);
			state = 2;
		}
		
		public var state:int = 0;
	}

}