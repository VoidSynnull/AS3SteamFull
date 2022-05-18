package game.scenes.virusHunter.shared.emitters
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class ShipExhaust extends Emitter2D
	{		
		public function init(antiGrav:Boolean = false):void
		{
			if(antiGrav)
			{
				counter = new Steady(20);
				addInitializer( new Position( new LineZone( new Point( -40, 0 ), new Point( 40, 0 ))));
				addInitializer( new Velocity( new DiscZone(null, 60, 0)));
				addInitializer( new ColorInit(0x9900c6df, 0xfffffffff));
			}
			else
			{
				counter = new Steady(10);
				addInitializer( new Position( new LineZone( new Point( -40, 0 ), new Point( 40, 0 ))));
				addInitializer( new Velocity( new DiscZone(null, 40, 0)));
				addInitializer( new ColorInit(0x99a3d9ff, 0xfffffffff));
			}
			
			addInitializer( new ImageClass( Dot, [2], true ));
			addInitializer( new ScaleImageInit( 1, 3.5));
			addInitializer( new Lifetime( 1.5 ));//.75
			
			addAction(new Age());
			addAction(new Move());
			addAction(new Fade());
			//addAction(new Rotate());
			//addAction(new ScaleImage());
			//addAction( new Accelerate(0, 650 ));
		}
		/*
		override protected function initParticle( particle:Particle ):void
		{
			Particle2D( particle ).angVelocity = Math.random() * 10;
			super.initParticle(particle);
		}
		*/
		
	}
}