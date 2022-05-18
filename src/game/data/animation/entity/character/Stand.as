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
	import game.components.scene.Cold;
	import game.creators.entity.EmitterCreator;
	import game.particles.emitter.characterAnimations.Breath;
	import game.systems.ParticleSystem;
	
	/**
	 * ...
	 * @author Bard
	 */
	public class Stand extends Default
	{
		private const LABEL_START_BREATH:String = "startBreath";
		private const LABEL_STOP_BREATH:String = "stopBreath";
		
		public function Stand()
		{
			super.apeXmlPath = super.XML_PATH + super.TYPE_APE + "navigation/stand" + ".xml";
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "navigation/stand" + ".xml";
			super.creatureXmlPath = super.XML_PATH + super.TYPE_CREATURE + "navigation/stand" + ".xml";
			super.petBabyQuadXmlPath = super.XML_PATH + super.TYPE_PET_BABYQUAD + "navigation/stand" + ".xml";
			super.horseXmlPath = super.XML_PATH + super.TYPE_HORSE + "stand" + ".xml";
			
			super.systems = [ParticleSystem];
			super.components = [Emitter];
		}
		
		override public function addComponentsTo(entity:Entity):void
		{
			if ( entity.has(Cold) )
			{
				var emitterEntity:Entity = getEmitter( entity, EMITTER_ID );
				emitterEntity.get(Emitter).remove = false;
			}
		}
		
		override public function reachedFrameLabel(entity:Entity, label:String):void
		{
			if ( entity.has(Cold) )
			{
				var emitterEntity:Entity = getEmitter( entity, EMITTER_ID );
				
				//check label
				if ( label == LABEL_START_BREATH )
				{
					var breath:Breath = Breath(emitterEntity.get(Emitter).emitter);
					Breath(emitterEntity.get(Emitter).emitter).counter.resume();
				}
				else if ( label == LABEL_STOP_BREATH )
				{
					Breath(emitterEntity.get(Emitter).emitter).counter.stop();
				}
			}
		}

		override public function remove(entity:Entity):void
		{
			var emitterEntity:Entity = _groupManager.getEntityById( EMITTER_ID, null, entity);
			if ( emitterEntity )
			{
				var emitter:Emitter = emitterEntity.get(Emitter);
				emitter.remove = true;
			}
		}
		
		private function getEmitter( character:Entity, id:String ):Entity
		{
			var emitterEntity:Entity = _groupManager.getEntityById( EMITTER_ID, null, character);
			if( emitterEntity == null )
			{
				emitterEntity = addEmitter( character );
			}
			return emitterEntity;
		}
		
		private function addEmitter(character:Entity):Entity
		{
			//var followTarget:Spatial = CharUtils.getJoint( character, CharUtils.HEAD ).get(Spatial);
			var followTarget:Spatial = character.get(Spatial);
			
			var emitter:Breath = new Breath();
			emitter.init( followTarget, -20 );
			var group:Group = OwningGroup(character.get(OwningGroup)).group;
			//var container:DisplayObjectContainer = Display(character.get(Display)).displayObject;	// contain within character
			var container:DisplayObjectContainer = Display(character.get(Display)).container;		// contain within scene
			var emitterEntity:Entity = EmitterCreator.create( group, container, emitter, 0, -22, character, EMITTER_ID, followTarget);
			return emitterEntity;
		}
		
		[Inject]
		public var _groupManager:GroupManager;
		
		private const EMITTER_ID:String = "breath";
		private const RATE:Number = 10;
	}

}