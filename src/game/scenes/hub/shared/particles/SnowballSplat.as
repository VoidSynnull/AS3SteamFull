package game.scenes.hub.shared.particles
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.data.TimedEvent;
	import game.util.SceneUtil;
	
	import nape.geom.Vec2;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	
	public class SnowballSplat extends Emitter2D 
	{
		public function init(group:Group, emitter:Entity):void
		{
			_group = group;
			_emitter = emitter;
			_velocity = new Velocity( new EllipseZone( new Point(0,0), 300, 400 ) )
		
			super.addInitializer( new ImageClass(Blob, [10, 0xffffff], true) );
			super.addInitializer( new Position( new EllipseZone( new Point(15,15), 10, 10 ) ));
			super.addInitializer( _velocity );
			super.addInitializer( new Lifetime(1, 0.5) );
			
			super.addAction( new Move() );
			//super.addAction( new Fade() );
			super.addAction( new Age() );
			super.addAction( new ScaleImage(1, 0) );
			super.addAction( new Accelerate( 0, 1) );
		}
		
		public function splat(velocity:Vec2):void{
			super.counter = new Steady(230);
			SceneUtil.addTimedEvent(_group, new TimedEvent(0.1, 1, stopSplat));
			SceneUtil.addTimedEvent(_group, new TimedEvent(1, 1, destroy));
		}
		
		
		private function stopSplat():void{
			super.counter = new Steady(0);
		}
		
		private function destroy():void{
			_group.removeEntity(_emitter);
			
			_group = null;
			_emitter = null;
		}
	
		
		private var _group:Group;
		private var _emitter:Entity;
		private var _velocity:Velocity;
		
	}
}