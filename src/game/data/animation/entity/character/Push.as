package game.data.animation.entity.character 
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.OwningGroup;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.managers.GroupManager;
	
	import game.components.Emitter;
	import game.creators.entity.EmitterCreator;
	import game.particles.emitter.characterAnimations.Sweat;
	import game.systems.ParticleSystem;
	import game.util.CharUtils;

	/**
	 * ...
	 * @author Bard
	 */
	public class Push extends Default
	{		
		private const LABEL_START_PARTICLES:String 	= "startParticles";
		private const EMITTER_ID:String = "sweat";
		
		public function Push()
		{
			super.apeXmlPath = super.XML_PATH + super.TYPE_APE + "navigation/push" + ".xml";
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "navigation/push" + ".xml";
			super.creatureXmlPath = super.XML_PATH + super.TYPE_CREATURE + "navigation/push" + ".xml";
			super.systems = [ParticleSystem];
			super.components = [Emitter];
		}
		
		override public function addComponentsTo(entity:Entity):void
		{
			var leftEyeTears:Entity = _groupManager.getEntityById(EMITTER_ID, null, entity);
			
			// If the emitter still exists when we try and create it, simply allow it to continue and turn off remove.
			if(leftEyeTears == null)
			{
				addSweat(entity, EMITTER_ID);
			}
			else
			{
				leftEyeTears.get(Emitter).remove = false;
			}
		}
		
		override public function reachedFrameLabel(entity:Entity, label:String):void
		{
			var leftEyeEmitter:Entity = _groupManager.getEntityById(EMITTER_ID, null, entity);
			
			//check label
			if ( label == LABEL_START_PARTICLES )
			{
				addComponentsTo(entity);
			}
		}
		
		override public function remove(entity:Entity):void
		{
			var leftEyeEmitterEntity:Entity = _groupManager.getEntityById(EMITTER_ID, null, entity);
			leftEyeEmitterEntity.get(Emitter).remove = true;
		}
		
		private function addSweat(character:Entity, id:String):void
		{
			// set target
			var followTarget:Spatial = CharUtils.getJoint( character, CharUtils.HEAD_JOINT ).get(Spatial);
			
			// create emitter entity
			var sweat:Sweat = new Sweat();
			sweat.init();
			var group:Group = OwningGroup(character.get(OwningGroup)).group;
			var container:DisplayObjectContainer = Display(character.get(Display)).displayObject;	// container within character
			//var container:DisplayObjectContainer = Display(character.get(Display)).container;		// container within scene
			var emitterEntity:Entity = EmitterCreator.create( group, container, sweat, 0, 0, character, id, followTarget);
		}
		
		[Inject]
		public var _groupManager:GroupManager;
	}

}