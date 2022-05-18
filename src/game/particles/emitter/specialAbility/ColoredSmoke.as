package game.particles.emitter.specialAbility
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Counter;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.zones.EllipseZone;
	
	public class ColoredSmoke extends Emitter2D
	{
		public function ColoredSmoke() 
		{
			
		}
		
		public function init( counter:Counter, color:Number, speedX:Number, speedY:Number, size:Number, life:Number,
							radiusX:Number, radiusY:Number, alphaInit:Number, driftX:Number, driftY:Number):void
		{
			this		.counter = counter;
			
			addInitializer( new ImageClass( Blob, [size, color], true ) );
			addInitializer( new AlphaInit( alphaInit, 1));
			addInitializer( new Lifetime( life, life ) );
			addInitializer( new Position( new EllipseZone( new Point( 0,0 ), radiusX, radiusY)));
			
			addAction( new Age( Quadratic.easeOut ) );
			addAction( new Move() );
			addAction( new RandomDrift( driftX, driftY ) );
			addAction( new ScaleImage( .7, 1.5 ) );
			addAction( new Fade(alphaInit, 0));
			addAction( new Accelerate( speedX, speedY) );
		}
	}
}


