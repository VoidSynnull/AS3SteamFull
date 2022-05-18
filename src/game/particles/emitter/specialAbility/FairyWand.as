package game.particles.emitter.specialAbility
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Rect;
	import org.flintparticles.common.displayObjects.Rect;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.AntiGravity;
	import org.flintparticles.twoD.actions.CircularAcceleration;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.PointZone;
	
	
	public class FairyWand extends Emitter2D
	{
		public function init(dir:Number = 1):void
		{
			super.counter = new Steady(20);
			
			addInitializer( new Lifetime(1, 10) );
			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 85, 10, -Math.PI, Math.PI ) ) );
			addInitializer( new Position( new PointZone(new Point(-95, 5)) ) );
			addInitializer( new ImageClass( Rect, [10, 10, 0xFFFFFF], true ) );
			addInitializer( new ScaleImageInit( .9, 1.1) );
			
			addAction( new Accelerate(-10, 20) );
			addAction( new Age() );
			addAction( new Move() );
			addAction( new Fade(1, 0));
			addAction( new AntiGravity(4) );
			addAction( new CircularAcceleration(5, 3) );
		}
		
		public function stopEmitter():void
		{
			super.counter.stop();
		}
		
		
	}
}