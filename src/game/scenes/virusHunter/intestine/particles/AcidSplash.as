package game.scenes.virusHunter.intestine.particles
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class AcidSplash extends Emitter2D
	{		
		public function init(x:Number, y:Number):void
		{
			this.counter = new Blast(25);
			
			this.addInitializer( new ImageClass( Blob, [3], true ) );
			this.addInitializer( new Position( new PointZone( new Point( x, y ) ) ) );
			this.addInitializer( new Velocity( new LineZone( new Point( -40, -230 ), new Point( 40, -230 ) ) ) );
			this.addInitializer( new ScaleImageInit(0.5, 1) );
			this.addInitializer( new ColorInit(0x66B4F075, 0x66B4F075) );
			this.addInitializer( new Lifetime(1) );
			
			this.addAction( new Age() );
			this.addAction( new Fade() );
			this.addAction( new RandomDrift( 100, 200 ) );
			this.addAction( new Move() );
			this.addAction( new Accelerate(0, 500));
		}
	}
}