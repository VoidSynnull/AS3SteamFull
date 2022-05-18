/**
 * ...
 * @author billy
 */

package game.particles.emitter 
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.TargetScale;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.ChooseInitializer;
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
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class WaterSplash extends Emitter2D
	{
		public function WaterSplash() 
		{
			
		}
		
		public function init(velocityFactor:Number, color1:uint = 0, color2:uint = 0, total:int = 0, size:Number = 3):void
		{
			if(total == 0) { total = 18 * velocityFactor; }
			
			// an single 'blast' of 30 particles will be created for this emitter.
			counter = new Blast(total);
			
			addInitializer( new ImageClass( Dot,[size],true ) );
			// particles will emit in a disc shape with a 25 px radius and 10 px dead-zone in the center.
			addInitializer( new Position( new DiscZone(new Point(0, 0), 25 * velocityFactor, 10 * velocityFactor) ) );
			// particles will pick one of four velocities
			addInitializer( new ChooseInitializer([new Velocity( new PointZone( new Point( 80 * velocityFactor, -150 * velocityFactor ))), 
											       new Velocity( new PointZone( new Point( -80 * velocityFactor, -150 * velocityFactor ))),
												   new Velocity( new PointZone( new Point( -30 * velocityFactor, -300 * velocityFactor ))),
												   new Velocity( new PointZone( new Point( 30 * velocityFactor, -300 * velocityFactor )))]));
			// particles will be a random scale between these values
			addInitializer( new ScaleImageInit( .25, 1) );
			// particles will be a random color in this range of 32 bit values.
			
			if(!color1)
			{
				color1 = 0x9966ccff;
			}
			
			if(!color2)
			{
				color2 = color1;
			}
			
			addInitializer( new ColorInit( color1, color2 ) );
			// particles will live between 1.2 and 1.5 seconds x factor
			addInitializer( new Lifetime( 1.2 * velocityFactor, 1.5 * velocityFactor) );

			// age will advance using a Quadtratic ease-in curve
			addAction( new Age(Quadratic.easeIn) );
			// particles will fade with age
			addAction( new Fade(.8, .1) );
			// particles will fade with age
			addAction( new TargetScale(0, 1) );
			// particles will drift randomly along their trajectory.
			addAction( new RandomDrift( 150 * velocityFactor, 0 ) );
			// add 'gravity'
			addAction( new Accelerate(0, 600) );
			// particles will move based on initial velocity and pull of gravity.
			addAction( new Move() );
		}
	}
}