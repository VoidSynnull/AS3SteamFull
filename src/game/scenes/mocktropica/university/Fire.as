package game.scenes.mocktropica.university
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ColorChange;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Droplet;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	
	public class Fire extends Emitter2D
	{
		public function init():void
		{
			counter = new Steady( 60 );		
			
			addInitializer( new Lifetime( .75, 1 ) );
			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 20, 10, -Math.PI, 0 ) ) );
			addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 3 ) ) );
			addInitializer( new ImageClass( Droplet, [1.5], true ) );
			
			addAction( new Age( ) );
			addAction( new Move( ) );
			addAction( new LinearDrag( 2 ) );
			addAction( new Accelerate( 0, -60 ) );
			addAction( new ColorChange( 0xFFFFCC00, 0x00CC0000 ) );
			addAction( new RotateToDirection() );

			
		}
	}
}