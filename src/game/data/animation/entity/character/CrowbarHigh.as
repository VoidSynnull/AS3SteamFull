package game.data.animation.entity.character 
{
	import ash.core.Entity;
	import engine.components.Display;
	import engine.components.OwningGroup;
	import engine.group.Group;
	import engine.managers.GroupManager;
	import engine.components.Spatial;
	import flash.display.DisplayObjectContainer;
	import game.components.Emitter;
	import game.creators.entity.EmitterCreator;
	import game.particles.emitter.characterAnimations.Sweat;
	import game.util.CharUtils;
	import game.systems.ParticleSystem;
	
	/**
	 * ...
	 * @author Bard
	 */
	public class CrowbarHigh extends Default
	{			
		private const LABEL_START_PARTICLES:String = "startParticles";
		private const LABEL_STOP_PARTICLES:String = "stopParticles";
		
		public function CrowbarHigh()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "crowbarHigh" + ".xml";
			super.systems = [ParticleSystem];
			super.components = [Emitter];
		}
		
		override public function addComponentsTo(entity:Entity):void
		{
			var emitterEntity:Entity = _groupManager.getEntityById( EMITTER_ID, null, entity);
			
			// If the emitter still exists when we try and create it, simply allow it to continue and turn off remove.
			if( emitterEntity == null )
			{
				addSweat( entity );
			}
			else
			{
				emitterEntity.get(Emitter).remove = false;
			}
		}
		
		override public function reachedFrameLabel(entity:Entity, label:String):void
		{
			var emitterEntity:Entity = _groupManager.getEntityById( EMITTER_ID, null, entity);
			
			//check label
			if ( label == LABEL_BEGINNING )
			{
				Sweat(emitterEntity.get(Emitter).emitter).counter.stop();
			}
			else if ( label == LABEL_START_PARTICLES )
			{
				Sweat(emitterEntity.get(Emitter).emitter).counter.resume();
			}
			else if ( label == LABEL_STOP_PARTICLES )
			{
				Sweat(emitterEntity.get(Emitter).emitter).counter.stop();
			}
		}
		
		override public function remove(entity:Entity):void
		{
			var emitterEntity:Entity = _groupManager.getEntityById( EMITTER_ID, null, entity);
			emitterEntity.get(Emitter).remove = true;
		}
		
		private function addSweat(character:Entity):void
		{
			var followTarget:Spatial = CharUtils.getJoint( character, CharUtils.HEAD_JOINT ).get(Spatial);
			
			var sweat:Sweat = new Sweat();
			sweat.init();
			sweat.counter.stop();
			var group:Group = OwningGroup(character.get(OwningGroup)).group;
			var container:DisplayObjectContainer = Display(character.get(Display)).displayObject;	// container within character
			//var container:DisplayObjectContainer = Display(character.get(Display)).container;		// container within scene
			var emitterEntity:Entity = EmitterCreator.create( group, container, sweat, 0, 0, character, EMITTER_ID, followTarget);
		}
		
		[Inject]
		public var _groupManager:GroupManager;
		
		private const EMITTER_ID:String = "sweat";
	}

}