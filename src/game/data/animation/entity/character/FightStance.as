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
	import game.components.audio.HitAudio;
	import game.creators.entity.EmitterCreator;
	import game.data.sound.SoundAction;
	import game.particles.emitter.characterAnimations.Breath;
	import game.systems.ParticleSystem;
	import game.util.CharUtils;

	public class FightStance extends Default
	{
		private const LABEL_LOOP:String = "loop";
		private const LABEL_START_BREATH:String = "startBreath";
		private const LABEL_STOP_BREATH:String = "stopBreath";
		private const EMITTER_ID:String = "breath";
		
		[Inject]
		public var _groupManager:GroupManager;
		
		public function FightStance()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "fightStance" + ".xml";
			super.systems = [ParticleSystem];
			super.components = [Emitter];
		}
		
		override public function reachedFrameLabel(entity:Entity, label:String):void
		{
			var emitterEntity:Entity = _groupManager.getEntityById( EMITTER_ID, null, entity);
			
			//check label
			if ( label == LABEL_START_BREATH )
			{
				Breath(emitterEntity.get(Emitter).emitter).counter.resume();
			}
			else if ( label == LABEL_STOP_BREATH )
			{
				Breath(emitterEntity.get(Emitter).emitter).counter.stop();
			}
			
			var hitAudio:HitAudio = entity.get(HitAudio);
			
			if(hitAudio != null)
			{
				if(label == SoundAction.STEP)
				{
					hitAudio.active = true;
					hitAudio.action = SoundAction.STEP;
				}
			}
		}
		
		override public function addComponentsTo(entity:Entity):void
		{
			var emitterEntity:Entity = _groupManager.getEntityById( EMITTER_ID, null, entity);
			
			// If the emitter still exists when we try and create it, simply allow it to continue and turn off remove.
			if( emitterEntity == null )
			{
				addBreath( entity );
			}
			else
			{
				emitterEntity.get(Emitter).remove = false;
			}
		}
		
		override public function remove(entity:Entity):void
		{
			var emitterEntity:Entity = _groupManager.getEntityById( EMITTER_ID, null, entity);
			emitterEntity.get(Emitter).remove = true;
		}
		
		private function addBreath(character:Entity):void
		{
			var followTarget:Spatial = CharUtils.getJoint( character, CharUtils.NECK_JOINT ).get(Spatial);
			
			var breath:Breath = new Breath();
			breath.init(character.get(Spatial));
			breath.counter.stop();
			var group:Group = OwningGroup(character.get(OwningGroup)).group;
			var container:DisplayObjectContainer = Display(character.get(Display)).displayObject;	// container within character
			//var container:DisplayObjectContainer = Display(character.get(Display)).container;		// container within scene
			var emitterEntity:Entity = EmitterCreator.create( group, container, breath, -20, -30, character, EMITTER_ID, followTarget);
		}
	}
}