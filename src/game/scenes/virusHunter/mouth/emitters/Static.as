package game.scenes.virusHunter.mouth.emitters
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Steady;
	
	import game.scenes.virusHunter.mouth.displayObjects.Bolt;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.actions.Rotate;
	
	public class Static extends Emitter2D
	{		
		public function init():void
		{
			counter = new Steady(20);
			
			addInitializer( new ImageClass( Bolt ));
			addInitializer( new Position( new LineZone( new Point( -25, 0 ), new Point( 25, 0 ))));
			addInitializer( new Velocity( new DiscZone(null, 50, 0)));
			addInitializer( new ColorInit( 0x99a3d9ff, 0xfffffffff ));
			addInitializer( new Lifetime( 1.5 ));//.75
			
			addAction(new Age());
			addAction(new Move());
			addAction(new Fade());
			addAction(new Rotate());
		}
	}
}