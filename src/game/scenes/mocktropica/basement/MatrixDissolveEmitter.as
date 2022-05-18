package game.scenes.mocktropica.basement
{	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.TimePeriod;
	import org.flintparticles.common.initializers.ChooseInitializer;
	import org.flintparticles.common.initializers.ExternalImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class MatrixDissolveEmitter extends Emitter2D
	{	
		public function MatrixDissolveEmitter() {
			
		}
		
		public function init():void
		{
			counter = new TimePeriod(400, 2.1);

			addInitializer( new ChooseInitializer([new ExternalImage("assets/scenes/mocktropica/basement/letter.swf")]));
			addInitializer( new Position( new RectangleZone(-40, -80, 20, 10)));
			addInitializer( new ScaleImageInit( 1, 1) );
			addInitializer( new Lifetime( 1 ) );
			
			addAction( new Age() );
			addAction( new Move() );
			addAction( new Accelerate(0, 100) );
			addAction( new Fade(.5, 0) );
		}
	}
}