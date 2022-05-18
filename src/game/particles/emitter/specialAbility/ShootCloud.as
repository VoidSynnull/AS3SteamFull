package game.particles.emitter.specialAbility 
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ChooseInitializer;
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
	
	
	public class ShootCloud extends Emitter2D
	{	
		public function ShootCloud() 
		{	
		}
		
		public function init(dir:int):void
		{
			super.counter = new Blast( 90 );
			addInitializer( new Lifetime( 1, 1 ) );
			var angle:Number;
			var angle2:Number;
			if (dir == -1)
			{
				angle =  -Math.PI - 1.745;
				angle2 = -Math.PI + 1.745;
			}
			else
			{
				angle = -70 * Math.PI / 180;
				angle2 = 70 * Math.PI / 180;
			}
				
			//angle *= -1;
			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 200, 10, angle,angle2) ) );
			addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 4 ) ) );
			addInitializer( new ImageClass( Blob, [15]) );
			addInitializer( new AlphaInit(.8,.8));
			addInitializer( new ChooseInitializer([new ImageClass(Blob, [3], true)]));
			
			addAction( new Age( ) );
			addAction( new Move( ) );
			addAction( new LinearDrag( 1 ) );
			addAction( new Accelerate( dir * 50, 0 ) );
		
			addAction( new ScaleImage( 1, 4 ) );
			addAction( new RotateToDirection() );
		}
	}
}

