package game.particles.emitter.specialAbility
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.AntiGravity;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;

	public class FireworkBlast extends Emitter2D
	{
		private var colors:Array = [ 0xFF3E3E, 0xFF9900, 0xFBF404, 0x66FF00, 0x0D91F2, 0xA476D1 ];
		
		
		public function init():void
		{
			super.counter = new Blast( 40 );
			
			addInitializer( new ImageClass( Dot, [3, colors[Math.floor(Math.random() * colors.length)]], true ) );
			addInitializer( new Lifetime( 12, 20 ) );;
			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 675, 10, -Math.PI, 0 ) ) );
			addInitializer( new Position( new DiscZone( new Point( Math.random()*400 - 200, Math.random()*100 - 50 ),4 ) ) );
			addInitializer( new ScaleImageInit( 0.6, 1) );
			
			addAction( new Age( ) );
			addAction( new Move( ) );
			addAction( new RotateToDirection() );
			addAction( new Accelerate( 0, 320 ) );
			//addAction( new LinearDrag( 2 ) );
			addAction( new AntiGravity(100, 100, 100, 4 ));
			//addAction( new CircularAcceleration(100, 3) );
			addAction( new Fade(.7, 0));
		}
	}
}