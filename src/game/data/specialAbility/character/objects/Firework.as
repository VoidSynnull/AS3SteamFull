package game.data.specialAbility.character.objects
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.particles.emitter.specialAbility.FireworkBlast;
	import game.particles.emitter.specialAbility.FireworkTrails;
	import game.util.SceneUtil;
	
	import org.flintparticles.twoD.emitters.Emitter2D;

	
	
	public class Firework
	{
		private var objEntity:Entity;
		private var count:Number = 0;
		
		public function init(group:Group, objectEntity:Entity):void
		{	
			objEntity = objectEntity;
			
			var motion:Motion = new Motion();
			motion.velocity = new Point(0, -100);
			motion.acceleration = new Point(0, -200);
			motion.friction = new Point(0, -100);
			objectEntity.add(motion);
			
			var display:Display = objectEntity.get(Display);
			var spatial:Spatial = objectEntity.get(Spatial);
			var emitter:Object = new FireworkTrails();
			emitter.init();
			
			var trailsEmitter:Entity = EmitterCreator.create( objectEntity.group, display.displayObject, emitter as Emitter2D, 0, 0 );
			
			SceneUtil.addTimedEvent(group, new TimedEvent(.4,10,startFireworks));
		}
		
		public function startFireworks():void
		{
			if(count > 3)
			{
				var emitter:Object = new FireworkBlast();
				emitter.init();
				EmitterCreator.create( objEntity.group, objEntity.group.shellApi.currentScene.groupContainer, emitter as Emitter2D, 0, 0 );
			}
			count++;
		}
	}
}