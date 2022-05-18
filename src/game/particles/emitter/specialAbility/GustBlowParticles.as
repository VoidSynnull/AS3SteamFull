package game.particles.emitter.specialAbility 
{	
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.initializers.ChooseInitializer;
	import org.flintparticles.common.initializers.ExternalSwfImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.Rotate;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.RotateVelocity;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	import org.flintparticles.twoD.initializers.Rotation;
	
	public class GustBlowParticles extends Emitter2D
	{	
		public function init(swf:MovieClip, yMin:Number, yMax:Number, xSpeed:Number, spikeRad:Number, spikeInc:Number):void
		{
			var top:Number = 200;
			super.counter = new Blast( 150 );
 			addInitializer( new ChooseInitializer([new ExternalSwfImage(swf)]));
			addInitializer( new Lifetime(4, 4) );
			addInitializer( new Velocity( new LineZone( new Point( xSpeed, yMin ), new Point( xSpeed, yMax ) ) ) );
			addInitializer( new Position( new RectangleZone( -400, -top, 0, 640 ) ) );
			addInitializer( new Rotation(0, 2*Math.PI) );
			// radians per second (full rotation in one second)
			addInitializer ( new RotateVelocity(2 * Math.PI, 2 * Math.PI) );
			
			addAction( new Age() );
			addAction( new Move() );
			addAction( new Rotate() );
			addAction( new SineVibrate(spikeRad, spikeInc));
		}
	}
}