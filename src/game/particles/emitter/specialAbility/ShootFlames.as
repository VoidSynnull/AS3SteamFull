package game.particles.emitter.specialAbility 
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ColorChange;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Line;
	import org.flintparticles.common.initializers.ColorInit;
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
	
	
	public class ShootFlames extends Emitter2D
	{	
		
		public function ShootFlames() 
		{	
	
		}
		
		public function init(dir:int, startColor:Number, endColor:Number):void
		{
			super.counter = new Blast( 60 );
			addInitializer( new Lifetime( 0.5, 1 ) );
			var angle:Number = 0;
			if (dir == -1)
				angle = Math.PI;
			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 500, 10, angle, angle) ) );
			addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 4 ) ) );
			addInitializer( new ImageClass( Line, [15]) );
			
			addAction( new Age( ) );
			addAction( new Move( ) );
			addAction( new LinearDrag( 1 ) );
			addAction( new Accelerate( dir * 100, 0 ) );
			addAction( new ColorChange( startColor, endColor ) );
			addAction( new ScaleImage( 1, 4 ) );
			addAction( new RotateToDirection() );

		}
		
		
	}
	
}