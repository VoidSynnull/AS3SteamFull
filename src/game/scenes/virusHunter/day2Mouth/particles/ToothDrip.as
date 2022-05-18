package game.scenes.virusHunter.day2Mouth.particles
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Droplet;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class ToothDrip extends Emitter2D
	{		
		public function init(point1:Point, point2:Point):void
		{
			this.counter = new Random(0, 2);
			
			this.addInitializer( new ImageClass( Droplet, [6], true ) );
			this.addInitializer( new Position( new LineZone( point1, point2 ) ) );
			this.addInitializer( new Velocity( new RectangleZone(-10, 20, 10, 50 ) ) );
			this.addInitializer( new ScaleImageInit(0.5, 1) );
			this.addInitializer( new ColorInit(0x66B4F075, 0x66B4F075) );
			this.addInitializer( new Lifetime(3) );
			
			this.addAction( new Age() );
			this.addAction( new Fade() );
			this.addAction( new RandomDrift( 0, 200 ) );
			this.addAction( new RotateToDirection());
			this.addAction( new Move() );
			this.addAction( new Accelerate(0, 300));
		}
	}
}