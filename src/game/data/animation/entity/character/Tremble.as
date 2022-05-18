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
	import game.components.entity.character.Character;
	import game.creators.entity.EmitterCreator;
	import game.creators.entity.character.CharacterCreator;
	import game.particles.emitter.characterAnimations.Sweat;
	import game.systems.ParticleSystem;
	import game.util.CharUtils;

	public class Tremble extends Default
	{
		private const LABEL_START_SWEAT:String = "startSweat";
		private const LABEL_STOP_SWEAT:String = "stopSweat";
		private const EMITTER_ID:String = "sweat";
		
		[Inject]
		public var _groupManager:GroupManager;
		
		public function Tremble()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "tremble" + ".xml";
			super.systems = [ParticleSystem];
			super.components = [Emitter];
		}
		
		override public function addComponentsTo(entity:Entity):void
		{
			// don't add particles to character tpes that don't animate
			if( super.isAnimateChar(entity) )
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
		}
		
		override public function reachedFrameLabel(entity:Entity, label:String):void
		{
			var emitterEntity:Entity = _groupManager.getEntityById( EMITTER_ID, null, entity);
			if( emitterEntity )
			{
				//check label
				if ( label == LABEL_BEGINNING )
				{
					Sweat(emitterEntity.get(Emitter).emitter).counter.stop();
				}
				else if ( label == LABEL_START_SWEAT )
				{
					Sweat(emitterEntity.get(Emitter).emitter).counter.resume();
				}
				else if ( label == LABEL_STOP_SWEAT )
				{
					Sweat(emitterEntity.get(Emitter).emitter).counter.stop();
				}
			}
		}
		
		override public function remove(entity:Entity):void
		{
			var emitterEntity:Entity = _groupManager.getEntityById( EMITTER_ID, null, entity);
			if( emitterEntity )
			{
				emitterEntity.get(Emitter).remove = true;
			}
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
	}
}