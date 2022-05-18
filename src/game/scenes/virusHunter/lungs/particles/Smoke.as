package game.scenes.virusHunter.lungs.particles
{
	import flash.geom.Rectangle;
	
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.MinimumDistance;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.WrapAroundBox;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.RectangleZone;
	import org.flintparticles.common.displayObjects.RadialEllipse;
	
	public class Smoke extends Emitter2D
	{		
		public function init(numParticles:uint, box:Rectangle):void
		{
			this.counter = new Blast(numParticles);
			
			this.addInitializer( new ImageClass( RadialEllipse, [20, 10, 0x000000], true ) );
			this.addInitializer( new Position( new RectangleZone(box.left, box.top, box.right, box.bottom) ) );
			this.addInitializer( new Velocity( new RectangleZone(-10, -10, 10, 10) ) );
			this.addInitializer( new ScaleImageInit(50, 80) );
			
			this.addAction( new Move() );
			this.addAction( new MinimumDistance(100, 100) );
			this.addAction( new WrapAroundBox(box.left, box.top, box.right, box.bottom) );
			this.addAction( new RandomDrift(50, 50) );
		}
	}
}