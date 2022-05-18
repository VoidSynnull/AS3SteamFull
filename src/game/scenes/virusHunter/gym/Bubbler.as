package game.scenes.virusHunter.gym
{
	import flash.geom.Point;
	
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Droplet;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Bubbler extends Emitter2D
	{
		public function Bubbler()
		{
			this.counter = new Steady(40);
			
			this.addInitializer( new ImageClass( Droplet, [2], true ) );
			this.addInitializer( new Position( new PointZone( new Point( 0, 0 ) ) ) );
			this.addInitializer( new Velocity( new LineZone( new Point( 25, -35 ), new Point( 55, -25 ) ) ) );
			this.addInitializer( new ScaleImageInit(0.5, 1) );
			this.addInitializer( new ColorInit(0x66CCCCCC, 0x66FFFFFF) );
			
			this.addAction( new RandomDrift( 100, 0 ) );
			this.addAction( new RotateToDirection());
			this.addAction( new DeathZone( new RectangleZone( 0, -10, 60, 20 ), true ) );
			this.addAction( new Move() );
			this.addAction( new Accelerate(0, 200));
		}
	}
}