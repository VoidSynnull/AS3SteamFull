package game.scenes.viking.beach.particles
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.TargetScale;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.initializers.ChooseInitializer;
	import org.flintparticles.common.initializers.ExternalImage;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class SandDiggingParticles extends Emitter2D
	{	
		public function SandDiggingParticles() {
			
		}
		
		public function init():void
		{
			counter = new Random(1, 4);
			
			//addInitializer( new ImageClass( DiveSand, [], true ) );
			addInitializer( new ChooseInitializer([new ExternalImage("assets/scenes/viking/beach/sand1.swf"), 
				new ExternalImage("assets/scenes/viking/beach/sand2.swf"),
				new ExternalImage("assets/scenes/viking/beach/sand3.swf")]));
			addInitializer( new Velocity( new PointZone( new Point( 100, -20 ) ) ) );
			addInitializer( new ScaleImageInit( .0, .1) );
			addInitializer( new Lifetime( 2 ) );
			
			addAction( new Age() );
			addAction( new Move() );
			addAction( new RandomDrift( 10, 10 ) );
			addAction( new Accelerate(0, -50) );
			addAction( new TargetScale(2, 10) );
			addAction( new Fade(0.5, 0) );
		}
	}
}