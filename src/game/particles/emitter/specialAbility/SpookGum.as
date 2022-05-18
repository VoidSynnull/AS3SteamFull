package game.particles.emitter.specialAbility
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.initializers.ChooseInitializer;
	import org.flintparticles.common.initializers.ExternalImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Friction;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.ScaleAll;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	
	
	public class SpookGum extends Emitter2D
	{
		public function init():void
		{
			super.counter = new Blast( 4 );
			
			addInitializer( new ChooseInitializer([new ExternalImage("assets/particles/skull.swf"), 
				new ExternalImage("assets/particles/skull2.swf"),
				new ExternalImage("assets/particles/skull3.swf")]));
			addInitializer( new Lifetime( 2, 4 ) );
			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 200, Math.random()*150 - 75, -Math.PI, 0 ) ) );
			addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 12 ) ) );
			
			addAction( new Age( ) );
			addAction( new Move( ) );
			addAction( new RandomDrift( 400, 200 ) );
			addAction( new Fade(1, 0) );
			//addAction(new AntiGravity(30) );
			//addAction( new Accelerate( Math.random()*400 - 200, Math.random()*400 - 200 ) );
			addAction( new ScaleAll(.4, Math.random()*.5 + .5));
			addAction( new Friction(20) );
			//addAction( new RotateToDirection() );
		}
	}
}