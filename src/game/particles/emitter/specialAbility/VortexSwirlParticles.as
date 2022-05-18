package game.particles.emitter.specialAbility 
{	
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import engine.components.Spatial;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.initializers.ChooseInitializer;
	import org.flintparticles.common.initializers.ExternalSwfImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.GravityWell;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class VortexSwirlParticles extends Emitter2D
	{	
		
		public function VortexSwirlParticles() 
		{
		}
		
		public function init(swf:MovieClip, charSpatial:Spatial, offsetY:Number, epsilon:Number):void
		{
			super.counter = new Blast( 100 );
			addInitializer( new ChooseInitializer([new ExternalSwfImage(swf)]));
			addInitializer( new Lifetime(3, 3) );
			addInitializer( new Velocity( new LineZone( new Point( 0, 0 ), new Point( 0, -100 ) ) ) );
			addInitializer( new Position( new LineZone( new Point( -150, 0 ), new Point( 150, 0 ) ) ) );
			
			addAction( new Age() );
			addAction( new Move() );
			addAction( new Fade(1, 0));
			addAction( new RotateToDirection());
			addAction( new GravityWell(1000, charSpatial.x, charSpatial.y + offsetY, epsilon) );
		}
	}
}