package game.particles.emitter.specialAbility 
{
	import flash.events.Event;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.ShellApi;
	import engine.components.Spatial;
	
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	import org.flintparticles.common.actions.Action;
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ColorChange;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.activities.FrameUpdatable;
	import org.flintparticles.common.activities.UpdateOnFrame;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.counters.Pulse;
	import org.flintparticles.common.counters.TimedBurst;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.displayObjects.Line;
	import org.flintparticles.common.events.EmitterEvent;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ChooseInitializer;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.particles.Particle;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.particles.Particle2D;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	
	
	public class GarlicBreath extends Emitter2D
	{	
		private var _player:Entity;
		private var _dir:Number;
		
		public function GarlicBreath() 
		{	
	
		}
		
		public function init(dir:int):void
		{
			super.counter = new TimedBurst(1,1,3);
			addInitializer( new Lifetime( .25, .75 ) );
			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 200, 10, 4.7,4.7) ) );
			addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 4 ) ) );
			addInitializer( new AlphaInit(.4,.8));
			addInitializer( new ChooseInitializer([new ImageClass(Blob, [5], true)]));
			
			addAction( new Age( ) );
			addAction( new Move( ) );
			addAction( new LinearDrag( 1 ) );
			addAction( new Accelerate( 0, -5 ) );
			addAction( new ScaleImage( 1, 4 ) );
			addAction( new RotateToDirection() );
		
			
		}
	}
	
}