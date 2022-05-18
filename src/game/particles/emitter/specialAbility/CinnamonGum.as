package game.particles.emitter.specialAbility 
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.initializers.ExternalImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Friction;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.actions.ScaleAll;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	
	
	public class CinnamonGum extends Emitter2D
	{	
		
		public function init():void
		{
			super.counter = new Blast( 20 );
			
			addInitializer( new ExternalImage( "assets/particles/cinnamongum.swf", true) );
			addInitializer( new Lifetime( .5, 1 ) );;
			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 200, Math.random()*150 - 75, -Math.PI, 0 ) ) );
			addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 12 ) ) );
			
			addAction( new Age( ) );
			addAction( new Move( ) );
			//addAction(new AntiGravity(30) );
			//addAction( new Accelerate( Math.random()*400 - 200, Math.random()*400 - 200 ) );
			addAction( new ScaleAll(Math.random() + .5 , 0));
			addAction( new Friction(200) );
			addAction( new RotateToDirection() );
		}
	}
	
	
}